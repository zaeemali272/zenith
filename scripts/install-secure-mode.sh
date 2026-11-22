#!/usr/bin/env bash
set -euo pipefail

if ! command -v ufw &>/dev/null; then
    if command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm ufw
    else
        echo "❌ ufw is not installed and pacman was not found." >&2
        exit 1
    fi
fi

# Determine target non-root username reliably
USER_NAME="${SUDO_USER:-$(logname 2>/dev/null || id -un)}"
if [[ -z "$USER_NAME" || "$USER_NAME" == "root" ]]; then
    echo "❌ Could not determine an unprivileged user for sudoers rule." >&2
    exit 1
fi

# Create secure-mode helper script if not present
SECURE_HELPER="/usr/local/bin/secure-mode"
sudo tee "$SECURE_HELPER" >/dev/null << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-status}" in
    enable|on)
        ufw enable
        ;;
    disable|off)
        ufw disable
        ;;
    status)
        ufw status verbose
        ;;
    *)
        echo "Usage: secure-mode {enable|disable|status}"
        exit 1
        ;;
esac
EOF
sudo chmod 755 "$SECURE_HELPER"

# Validate sudoers entry with visudo before installing
TMP_SUDOERS="$(mktemp)"
echo "$USER_NAME ALL=(ALL) NOPASSWD: $SECURE_HELPER" > "$TMP_SUDOERS"

if sudo visudo -cf "$TMP_SUDOERS" >/dev/null 2>&1; then
    sudo install -m 440 -o root -g root "$TMP_SUDOERS" /etc/sudoers.d/secure-mode
    rm -f "$TMP_SUDOERS"
    echo "✅ Secure Mode system installed and verified."
else
    rm -f "$TMP_SUDOERS"
    echo "❌ Sudoers validation failed! Aborting without modifying /etc/sudoers.d." >&2
    exit 1
fi
