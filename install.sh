#!/usr/bin/env bash
set -euo pipefail

# --- Root Check ---
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please do not run this script as root. Use a user with sudo privileges."
    exit 1
fi

if ! command -v sudo &>/dev/null; then
    echo "❌ 'sudo' is not installed. Please install it and add your user to the wheel group."
    exit 1
fi

DOTS_DIR="$(pwd)"
export DOTS_DIR
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# Flags
export SKIP_GAMING=0
export SKIP_THEMES=0
export SKIP_RECOMMENDED=0
export SKIP_EXTRAS=0
export SKIP_FONTS=0
export SKIP_SCRIPTS=0
export AUTO_INSTALL=0
export JSON_OUTPUT=0

# Parse Arguments
for arg in "$@"; do
    case $arg in
        --no-gaming) export SKIP_GAMING=1 ;;
        --no-themes) export SKIP_THEMES=1 ;;
        --no-recommended) export SKIP_RECOMMENDED=1 ;;
        --no-extras) export SKIP_EXTRAS=1 ;;
        --no-fonts) export SKIP_FONTS=1 ;;
        --no-scripts) export SKIP_SCRIPTS=1 ;;
        --auto|--unattended) export AUTO_INSTALL=1 ;;
        --json) export JSON_OUTPUT=1 ;;
    esac
done

# Load Modules
for f in modules/*.sh; do source "$f"; done

# --- Super User System Tuning ---
system_tuning() {
    log_step "⚡ Tuning system for Zenith performance..."
    
    # 1. Pacman optimization
    sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
    sudo sed -i 's/^#Color/Color\nILoveCandy/' /etc/pacman.conf
    
    # 2. Makepkg optimization (Speed up builds)
    sudo sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf
    sudo sed -i 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q --threads=0 -)/' /etc/makepkg.conf
    
    # 3. ZRAM & Swap (Stability)
    setup_zram
    log_success "System tuning complete."
}

# --- Pre-Network Fix ---
pre_network_fix() {
    log_step "💾 Checking network and installing essential tools..."
    
    # Install essentials first (if possible)
    if sudo pacman -S --needed --noconfirm nano rsync git jq &>/dev/null; then
        log_success "Essential tools installed."
    else
        log_warn "Could not install tools immediately. Checking network..."
    fi

    # Check internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "Internet connection detected. Skipping DNS override."
    else
        log_warn "No internet connection. Attempting to fix DNS..."
        if [[ -f /etc/resolv.conf ]]; then
            sudo cp /etc/resolv.conf /etc/resolv.conf.bak
        fi
        echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
        
        # Retry install
        sudo pacman -S --needed --noconfirm nano rsync git jq || log_error "Failed to install essential tools even after DNS fix."
    fi
}

# --- System Preparation (Mirrors) ---
system_prep() {
    if has_run "system_prep"; then
        log_success "System preparation already completed. Skipping Reflector."
        return
    fi

    log_step "🌐 Optimizing Arch mirrors with Reflector..."
    sudo pacman -S --needed --noconfirm reflector || log_warn "Reflector install failed, skipping mirror optimization."
    sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || log_warn "Mirror optimization failed."
    
    mark_done "system_prep"
    log_success "System preparation complete."
}

# --- Interactive Script Runner ---
run_optional_scripts() {
    log_step "🛠️ Checking for optional scripts..."
    for script in scripts/*.sh; do
        [[ -f "$script" ]] || continue
        script_name=$(basename "$script")
        
        if [[ "$AUTO_INSTALL" -eq 1 ]]; then
             log_step "Auto-skipping optional script: $script_name (Run manually if needed)"
             continue
        fi

        echo -e "\n${BOLD}${CYAN}❓ Would you like to run '$script_name'?${NC}"
        read -p "(y/n): " choice
        case "$choice" in
            [yY]* ) log_step "Running $script_name..."; bash "$script" || log_error "$script_name failed." ;;
            * ) log_step "Skipping $script_name." ;;
        esac
    done
}

# --- Feature Groups ---
minimal_install() {
    pre_network_fix
    system_prep
    system_tuning
    detect_hardware
    install_minimal_packages
    sync_dotfiles
    set_fish_shell
    setup_post_boot_service
    setup_autologin

    installation_summary "Minimal"
    echo -e "\n${YELLOW}${BOLD}Rebooting in 10s... (Press Ctrl+C to cancel)${NC}"
    sleep 10 && sudo reboot
}

full_install() {
    pre_network_fix
    system_prep
    system_tuning
    detect_hardware
    install_minimal_packages
    install_remaining_packages
    sync_etc_config
    sync_dotfiles
    setup_xdg_dirs
    set_fish_shell
    setup_system_services
    bash scripts/power-profile-setup.sh
    setup_autologin
    optimize_bootloader
    bash scripts/install-fusuma.sh
    [[ "$SKIP_SCRIPTS" -eq 0 ]] && run_optional_scripts
    
    installation_summary "Full"
    echo -e "\n${YELLOW}${BOLD}Rebooting in 10s... (Press Ctrl+C to cancel)${NC}"
    sleep 10 && sudo reboot
}

packages_only() {
    system_prep
    detect_hardware
    install_minimal_packages
    install_remaining_packages
    log_success "Package installation complete."
}

configs_only() {
    sync_etc_config
    sync_dotfiles
    setup_xdg_dirs
    log_success "Configuration sync complete."
}

run_specific_script() {
    log_step "📂 Listing available scripts in 'scripts/'..."
    local script_files=()
    for s in scripts/*.sh; do
        [[ -f "$s" ]] && script_files+=("$s")
    done

    if [[ ${#script_files[@]} -eq 0 ]]; then
        log_warn "No .sh scripts found in scripts/ directory."
        return
    fi

    local script_names=()
    for s in "${script_files[@]}"; do
        script_names+=("$(basename "$s")")
    done
    
    script_names+=("<- Back to Main Menu")
    
    ask_choice "Select a script to execute:" "${script_names[@]}"
    
    if [[ $MENU_CHOICE -eq $((${#script_names[@]} - 1)) ]]; then
        return 1
    fi
    
    local selected_script="${script_files[$MENU_CHOICE]}"
    log_step "Running $selected_script..."
    bash "$selected_script" || log_error "Execution of $selected_script failed."
    
    echo -e "\n${GREEN}Script finished.${NC}"
    read -p "Press Enter to return to menu..."
    return 0
}

# --- Main Flow ---
print_header

if [[ "$AUTO_INSTALL" -eq 1 ]]; then
    log_step "🚀 Auto-Install Mode Enabled. Starting Minimal Installation..."
    minimal_install
    exit 0
fi

while true; do
    print_header
    options=(
        "Minimal Installation (Recommended: Base system + Post-boot GUI installer)"
        "Full Installation (The Complete Zenith Experience, all at once)"
        "Packages Only (Install all system and AUR packages)"
        "Configs Only (Sync dotfiles and /etc configurations)"
        "Setup Quickshell (Clone/Sync Zenith-Shell for Quickshell)"
        "Run Specific Script (Select from scripts/ directory)"
        "Exit"
    )

    ask_choice "Welcome, $USER. What would you like to do?" "${options[@]}"

    case $MENU_CHOICE in
        0) minimal_install; break ;;
        1) full_install; break ;;
        2) packages_only; break ;;
        3) configs_only; break ;;
        4) 
            setup_quickshell
            echo -e "\n${GREEN}Press Enter to return to the menu...${NC}"
            read -r
            ;;
        5) run_specific_script || true ;;
        6) log_step "Exiting. Have a great day!"; exit 0 ;;
    esac
done
