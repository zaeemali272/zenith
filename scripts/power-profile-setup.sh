#!/usr/bin/env bash
set -euo pipefail

# -------------------- sanity check --------------------
if [[ $EUID -eq 0 ]]; then
  echo "Please run as a normal user with sudo privileges, not root."
  exit 1
fi

USER_HOME="$HOME"
USER_NAME="$USER"
BIN_DIR="$USER_HOME/.local/bin"
UDEV_DIR="/etc/udev/rules.d"
LOG_DIR="$USER_HOME/.cache"
SCRIPT="$BIN_DIR/power-profile-daemon.sh"
RULE_FILE="$UDEV_DIR/99-governor.rules"
LOG_FILE="$LOG_DIR/power-profile.log"
SUDOERS_FILE="/etc/sudoers.d/99-power-profile"

# remove previous versions
rm -f "$SCRIPT"
sudo rm -f "$RULE_FILE" "$SUDOERS_FILE"

mkdir -p "$BIN_DIR" "$LOG_DIR"

echo "[*] Installing universal power profile daemon..."

# We use 'EOF' (quoted) to prevent interpolation inside the setup script
# Then we use sed to inject the variables we need.
cat > "$SCRIPT" << 'EOF'
#!/usr/bin/env bash
# UNIVERSAL POWER PROFILE DAEMON
# Applies CPU settings based on AC/Battery or manual profile

# Baked-in config from setup (replaced by sed)
REAL_USER="__REAL_USER__"
USER_HOME="__USER_HOME__"
STATE_FILE="$USER_HOME/.cache/power-profile-state"
LOG_FILE="$USER_HOME/.cache/power-profile.log"

mkdir -p "$(dirname "$LOG_FILE")"

# Detection helper
AVAILABLE_GOVS=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "performance powersave")
HAS_EPP=$([[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]] && echo 1 || echo 0)
HAS_TURBO=$([[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]] && echo 1 || echo 0)

# Status command: return current profile and exit
if [[ "${1:-}" == "status" ]]; then
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        # Fallback to governor detection
        current_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "powersave")
        echo "$current_gov"
    fi
    exit 0
fi

# Determine target profile
if [[ $# -gt 0 ]]; then
    TARGET="$1"
else
    # Auto-switch based on AC/Battery
    AC_PATH=""
    for p in /sys/class/power_supply/*/online; do
        AC_PATH="$p"
        if [[ "$p" == *"ADP"* || "$p" == *"AC"* ]]; then
            break
        fi
    done

    if [[ -n "$AC_PATH" ]] && [[ -f "$AC_PATH" ]]; then
        AC_ON=$(cat "$AC_PATH")
        TARGET=$([[ "$AC_ON" -eq 1 ]] && echo "performance" || echo "powersave")
    else
        TARGET="powersave"
    fi
fi

# Profile-to-setting mapping logic
GOV="powersave"
EPP="balance_performance"
TURBO="0" # 0 = on, 1 = off

case "$TARGET" in
    performance|turbo)
        GOV="performance"
        EPP="performance"
        TURBO="0"
        ;;
    balanced)
        GOV="powersave"
        EPP="balance_performance"
        TURBO="0"
        # If schedutil is available, we might want it if NOT on intel_pstate
        if [[ "$AVAILABLE_GOVS" == *"schedutil"* ]] && [[ "$HAS_EPP" == 0 ]]; then
            GOV="schedutil"
        fi
        ;;
    powersave)
        GOV="powersave"
        EPP="power"
        TURBO="1"
        ;;
    *)
        # fallback to what user provided or powersave
        GOV="${TARGET}"
        ;;
esac

# Apply Governor
for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
    if [[ $EUID -eq 0 ]]; then
        echo "$GOV" > "$f" 2>/dev/null || true
    else
        echo "$GOV" | sudo /usr/bin/tee "$f" > /dev/null 2>/dev/null || true
    fi
done

# Apply EPP if available
if [[ "$HAS_EPP" == 1 ]]; then
    for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/energy_performance_preference; do
        if [[ $EUID -eq 0 ]]; then
            echo "$EPP" > "$f" 2>/dev/null || true
        else
            echo "$EPP" | sudo /usr/bin/tee "$f" > /dev/null 2>/dev/null || true
        fi
    done
fi

# Apply Turbo if available
if [[ "$HAS_TURBO" == 1 ]]; then
    if [[ $EUID -eq 0 ]]; then
        echo "$TURBO" > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    else
        echo "$TURBO" | sudo /usr/bin/tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>/dev/null || true
    fi
fi

# Update state for UI
echo "$TARGET" > "$STATE_FILE"
if [[ $EUID -eq 0 ]]; then
    chown "$REAL_USER":"$REAL_USER" "$STATE_FILE" 2>/dev/null || true
fi

# Log
echo "$(date '+%a %b %d %T %Y') | Applied profile: $TARGET (Gov: $GOV, EPP: $EPP, Turbo: $TURBO)" >> "$LOG_FILE"
EOF

sed -i "s|__REAL_USER__|$USER_NAME|g" "$SCRIPT"
sed -i "s|__USER_HOME__|$USER_HOME|g" "$SCRIPT"

chmod +x "$SCRIPT"

# -------------------- udev rule --------------------
echo "[*] Creating udev rule..."
sudo tee "$RULE_FILE" > /dev/null <<EOF
# Auto-run power profile daemon on AC/Battery change
ACTION=="change", SUBSYSTEM=="power_supply", RUN+="$SCRIPT"
EOF

# -------------------- sudoers entry --------------------
echo "[*] Adding sudoers entries for governor control..."
sudo tee "$SUDOERS_FILE" > /dev/null <<EOF
# allow user to change CPU governors and EPP without password
$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/devices/system/cpu/intel_pstate/no_turbo
EOF

# -------------------- reload udev --------------------
echo "[*] Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "[✔] Setup complete!"
echo " - Power profile daemon installed at $SCRIPT"
echo " - Supports EPP and Intel Turbo if available"
echo " - AC/Battery detection is now dynamic"
