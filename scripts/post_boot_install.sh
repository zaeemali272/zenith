#!/usr/bin/env bash
set -euo pipefail

# Detect DOTS_DIR dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTS_DIR="$(dirname "$SCRIPT_DIR")"

# Load Modules
for f in "$DOTS_DIR/modules/"*.sh; do 
    # shellcheck source=/dev/null
    source "$f"
done

# --- Sudo Keep-Alive ---
SUDO_KEEP_ALIVE_PID=0

stop_sudo_keepalive() {
    if [[ ${SUDO_KEEP_ALIVE_PID:-0} -ne 0 ]]; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
        SUDO_KEEP_ALIVE_PID=0
    fi
}

cleanup() {
    stop_sudo_keepalive
}
trap cleanup EXIT INT TERM

init_sudo() {
    log_step "🔐 Authenticating sudo for post-boot tasks..."
    sudo -v || { log_error "Sudo authentication failed."; exit 1; }
    
    # Background loop to keep sudo alive
    (
        while true; do
            sudo -n true
            sleep 60
        done
    ) &>/dev/null &
    SUDO_KEEP_ALIVE_PID=$!
    log_success "Sudo keep-alive started (PID: $SUDO_KEEP_ALIVE_PID)"
}

# --- Main Installation ---
run_phase_2() {
    init_sudo
    log_step "🚀 Starting Zenith Post-Boot Installation..."
    
    # Run all the remaining installation and setup steps
    detect_hardware
    install_remaining_packages
    setup_xdg_dirs
    set_fish_shell
    setup_system_services
    optimize_bootloader
    
    # Self-destruct sequence
    log_step "✅ Installation Complete. Cleaning up autostart..."
    local execs_file="$HOME/.config/hypr/hyprland/execs.conf"
    if [[ -f "$execs_file" ]]; then
        # Remove the specific line
        sed -i "/post_boot_install.sh/d" "$execs_file"
        log "Removed autostart from $execs_file."
    fi

    # Cleanup old method files if they exist
    rm -f "$HOME/.config/systemd/user/zenith-post-boot.service"
    rm -f "$HOME/.config/hypr/autostart_once.conf"

    log_success "Zenith is fully installed! Enjoy."
    sleep 5
}

run_phase_2
