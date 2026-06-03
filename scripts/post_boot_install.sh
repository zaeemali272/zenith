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

# --- Main Installation ---
run_phase_2() {
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
