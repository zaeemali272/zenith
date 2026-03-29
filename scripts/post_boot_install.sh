#!/usr/bin/env bash
set -euo pipefail

# Detect DOTS_DIR dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTS_DIR="$(dirname "$SCRIPT_DIR")"
export JSON_OUTPUT=0

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

# --- UI Integrity Check ---
check_ui_running() {
    local qs_cmd="qs --path $HOME/.config/zenith-installer/installer.qml"
    
    # Wait a few seconds for autostart to kick in
    sleep 3
    
    if pgrep -f "installer.qml" > /dev/null; then
        log_success "Post-boot UI is running."
    else
        log_warn "Post-boot UI not detected. Launching in terminal fallback..."
        # Launching in a new terminal so user can see it
        kitty --title "Zenith Post-Install" sh -c "$qs_cmd || { echo 'UI Failed to launch. Press enter to exit...'; read; }" &
        disown
    fi
}

# --- Main Installation for Phase 2 ---
run_phase_2() {
    # Ensure JSON output for the UI
    export JSON_OUTPUT=1
    
    local qs_cmd="qs --path $HOME/.config/zenith-installer/installer.qml"
    
    # Kill any existing instance to avoid "stuck" UI
    pkill -f "installer.qml" || true
    
    # Redirect all subsequent output to the UI
    # exec > >($qs_cmd) 2>&1

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
