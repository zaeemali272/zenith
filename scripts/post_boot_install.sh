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
    systemctl --user disable --now zenith-post-boot.service || true
    rm -f "$HOME/.config/systemd/user/zenith-post-boot.service"
    rm -f "$HOME/.config/hypr/autostart_once.conf"
    systemctl --user daemon-reload

    log_success "Zenith is fully installed! Enjoy."
    sleep 5
}

run_phase_2
