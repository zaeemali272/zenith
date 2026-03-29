#!/usr/bin/env bash
set -euo pipefail

# Detect DOTS_DIR dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTS_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure JSON output for the UI
export JSON_OUTPUT=1

# Launch the QML installer application in the background
# This ensures the GUI is visible and ready to receive logs.

# Default values for SKIP flags if not set (to avoid unbound variable errors)
export SKIP_FONTS=${SKIP_FONTS:-0}
export SKIP_GAMING=${SKIP_GAMING:-0}
export SKIP_THEMES=${SKIP_THEMES:-0}
export SKIP_RECOMMENDED=${SKIP_RECOMMENDED:-0}
export SKIP_EXTRAS=${SKIP_EXTRAS:-0}

# Load Modules
for f in "$DOTS_DIR/modules/"*.sh; do 
    # shellcheck source=/dev/null
    source "$f"
done

# --- Main Installation ---
# This function now contains the primary installation logic and logs output to the QML UI.
run_phase_2() {
    # Kill any existing instance to avoid "stuck" UI (now potentially redundant, but harmless)
    pkill -f "installer.qml" || true
    
    # Redirect all subsequent output to the UI
    # Use exec to replace the current shell process with qs, piping its stdin/stdout/stderr
    # This ensures that all logs from this script go directly to the QML UI.
    # Removed exec redirection as Process component handles output capture.

    log_step "🚀 Starting Zenith Post-Boot Installation..."
    
    # Run all the remaining installation and setup steps
    detect_hardware
    install_remaining_packages
    sync_etc_config
    setup_xdg_dirs
    set_fish_shell
    setup_system_services
    optimize_bootloader
    
    # Send finish signal to UI
    echo '{"type": "finish"}'

    # Self-destruct sequence
    log_step "✅ Installation Complete. Cleaning up autostart..."
    local execs_file="$HOME/.config/hypr/hyprland/execs.conf"
    if [[ -f "$execs_file" ]]; then
        # Remove the specific line
        sed -i "/qs --path.*installer.qml/d" "$execs_file"
        log "Removed autostart from $execs_file."
    fi

    # Cleanup old method files if they exist
    rm -f "$HOME/.config/systemd/user/zenith-post-boot.service"
    rm -f "$HOME/.config/hypr/autostart_once.conf"

    log_success "Zenith is fully installed! Enjoy."
    sleep 5
}

run_phase_2
