#!/usr/bin/env bash
set -euo pipefail

export DOTS_DIR="$HOME/Documents/Linux/Dots/zenith"
export JSON_OUTPUT=0

# Load Modules
for f in "$DOTS_DIR/modules/"*.sh; do 
    # shellcheck source=/dev/null
    source "$f"
done

# --- Main Installation for Phase 2 ---
run_phase_2() {
    log_step "🚀 Starting Zenith Post-Boot Installation..."
    
    # Run all the remaining installation and setup steps
    install_remaining_packages
    sync_etc_config
    setup_xdg_dirs
    set_fish_shell
    setup_system_services
    setup_cpu_governor
    optimize_bootloader
    
    # Self-destruct sequence
    log_step "✅ Installation Complete. Removing post-boot service..."
    systemctl --user disable --now zenith-post-boot.service
    rm -f "$HOME/.config/systemd/user/zenith-post-boot.service"
    rm -f "$HOME/.config/hypr/autostart_once.conf"
    systemctl --user daemon-reload

    log_success "Zenith is fully installed! Enjoy."
    sleep 5
}

run_phase_2
