#!/usr/bin/env bash
set -euo pipefail

# --- Initial Setup ---
DOTS_DIR="$(pwd)"
export DOTS_DIR

# --- Load Modules Early (For Colors and UI) ---
if [[ -d "modules" ]]; then
    for f in modules/*.sh; do source "$f"; done
else
    echo "❌ 'modules' directory not found. Please run from the zenith/ root."
    exit 1
fi

# --- Error Handling ---
error_handler() {
    local exit_code=$1
    local line_no=$2
    if command -v log_error &>/dev/null; then
        log_error "An error occurred at line $line_no (Exit Code: $exit_code)"
    else
        echo "ERR: An error occurred at line $line_no (Exit Code: $exit_code)"
    fi
    echo -e "${RED:-}The script encountered an issue and had to stop.${NC:-}"
}
trap 'error_handler $? $LINENO' ERR

cleanup() {
    rm -f /tmp/zenith_temp_* 2>/dev/null
}
trap cleanup EXIT

# --- Root Check ---
if [[ $EUID -eq 0 ]]; then
    echo "❌ Please do not run this script as root. Use a user with sudo privileges."
    exit 1
fi

if ! command -v sudo &>/dev/null; then
    echo "❌ 'sudo' is not installed. Please install it and add your user to the wheel group."
    exit 1
fi

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

# --- Super User System Tuning ---
system_tuning() {
    log_step "⚡ Tuning system for Zenith performance..."
    
    # 1. Pacman optimization
    sudo sed -i 's/^\(#\|\)ParallelDownloads = [0-9]*/ParallelDownloads = 10/' /etc/pacman.conf
    sudo sed -i 's/^#Color/Color\nILoveCandy/' /etc/pacman.conf
    
    # 2. Makepkg optimization (Speed up builds)
    local nprocs=$(nproc)
    sudo sed -i "s/-j[0-9]*/-j$nprocs/g;s/^#MAKEFLAGS=\"-j[0-9]*\"/MAKEFLAGS=\"-j$nprocs\"/" /etc/makepkg.conf
    sudo sed -i "s/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q --threads=0 -)/" /etc/makepkg.conf
    sudo sed -i "s/COMPRESSZST=(zstd -c -T0 -)/COMPRESSZST=(zstd -c -T0 --threads=0 -)/" /etc/makepkg.conf
    
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
        echo -e "nameserver 8.8.8.8
nameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
        
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

        echo -e "
${BOLD}${CYAN}❓ Would you like to run '$script_name'?${NC}"
        read -p "(y/n): " choice </dev/tty || choice="n"
        case "$choice" in
            [yY]* ) 
                log_step "Running $script_name..."
                # Run in a subshell, handle errors without exiting, and ensure no hang
                (bash "$script" || log_error "$script_name failed.") 
                ;;
            * ) 
                log_step "Skipping $script_name." 
                ;;
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
    echo -e "
${YELLOW}${BOLD}Rebooting in 10s... (Press Ctrl+C to cancel)${NC}"
    sleep 10 && sudo reboot
}

full_install() {
    pre_network_fix
    system_prep
    system_tuning
    detect_hardware
    install_minimal_packages
    install_remaining_packages
    sync_dotfiles
    setup_xdg_dirs
    set_fish_shell
    setup_system_services
    bash scripts/power-profile-setup.sh || log_warn "Power profile setup failed."
    setup_autologin
    optimize_bootloader
    bash scripts/install-fusuma.sh || log_warn "Fusuma installation failed."
    
    echo -e "
${BOLD}${CYAN}❓ Would you like to install extra themes, animations and wallpapers?${NC}"
    read -p "(y/n): " choice </dev/tty || choice="n"
    if [[ "$choice" =~ ^[yY] ]]; then
        setup_extra_assets
    fi

    if [[ "$SKIP_SCRIPTS" -eq 0 ]]; then
        run_optional_scripts
    fi
    
    installation_summary "Full"
    echo -e "
${YELLOW}${BOLD}Rebooting in 10s... (Press Ctrl+C to cancel)${NC}"
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
    sync_dotfiles
    setup_xdg_dirs
    log_success "Configuration sync complete."
}

run_specific_script() {
    log_step "📂 Listing available scripts in 'scripts/'..."
    local script_files=()
    local script_display_names=() # For displaying to the user

    # Populate script_files and script_display_names
    for s in scripts/*.sh; do
        if [[ -f "$s" ]]; then
            script_files+=("$s")
            script_display_names+=("$(basename "$s")")
        fi
    done

    if [[ ${#script_files[@]} -eq 0 ]]; then
        log_warn "No .sh scripts found in scripts/ directory."
        return
    fi

    # Display scripts with their indices for user selection
    echo -e "
Available scripts:"
    for i in "${!script_display_names[@]}"; do
        printf "  %d) %s
" "$((i + 1))" "${script_display_names[i]}"
    done
    echo ""

    echo -e "${BOLD}${CYAN}Enter script numbers or ranges (e.g., '1 3-5 7'):${NC}"
    read -p "> " script_selection_input </dev/tty || { echo -e "${RED}Input read error.${NC}"; return 1; }

    # --- Parse and Execute Scripts ---
    declare -a scripts_to_run_indices=() # Stores 0-based indices of scripts to run
    
    # Replace commas with spaces to treat both as separators, then process
    local sanitized_input=$(echo "$script_selection_input" | tr ',' ' ')
    
    # Split the sanitized input by whitespace, ensuring each part is processed individually
    local IFS=$'
'
    local input_parts=($(echo "$sanitized_input" | xargs -n1))

    for part in "${input_parts[@]}"; do
        # Trim whitespace from the part (already handled by xargs -n1, but good practice)
        part=$(echo "$part" | xargs) 

        if [[ -z "$part" ]]; then
            continue # Skip empty parts
        fi

        if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            # It's a range like "1-5"
            local start_num=${BASH_REMATCH[1]}
            local end_num=${BASH_REMATCH[2]}

            # Convert to 0-based indices for array access
            local start_index=$((start_num - 1))
            local end_index=$((end_num - 1))

            # Validate range
            if [[ "$start_index" -lt 0 || "$end_index" -ge "${#script_files[@]}" || "$start_index" -gt "$end_index" ]]; then
                log_warn "Invalid range '$part'. Please use numbers between 1 and ${#script_files[@]}."
                continue
            fi

            # Add all indices in the range to the list
            for ((i=$start_index; i<=$end_index; i++)); do
                scripts_to_run_indices+=("$i")
            done
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            # It's a single number
            local script_index=$((part - 1))

            # Validate number
            if [[ "$script_index" -lt 0 || "$script_index" -ge "${#script_files[@]}" ]]; then
                log_warn "Invalid script number '$part'. Please use numbers between 1 and ${#script_files[@]}."
                continue
            fi
            scripts_to_run_indices+=("$script_index")
        else
            log_warn "Invalid input format '$part'. Please use numbers or ranges (e.g., '1 3-5')."
        fi
    done

    # Remove duplicate indices and sort them to ensure execution order is predictable and avoid re-running
    # Use process substitution with sort for efficiency and to handle potential newlines in array elements if they were complex.
    local IFS=$'
'
    local sorted_indices=($(printf "%s
" "${scripts_to_run_indices[@]}" | sort -nu))
    scripts_to_run_indices=("${sorted_indices[@]}")

    if [[ ${#scripts_to_run_indices[@]} -eq 0 ]]; then
        log_warn "No valid scripts selected or found."
        echo -e "
${GREEN}Returning to menu...${NC}"
        read -p "Press Enter to continue..."
        return 0 # Exit this function, effectively returning to the main menu loop
    fi

    # Execute the selected scripts
    for index in "${scripts_to_run_indices[@]}"; do
        local selected_script="${script_files[$index]}"
        local script_name=$(basename "$selected_script")
        log_step "Running script: '$script_name'..."
        
        # Execute the script. If it fails, log an error but continue to the next script.
        if bash "$selected_script"; then
            log_success "'$script_name' finished successfully."
        else
            # The error handler trap should catch most bash errors, but this provides a final message if the script exits non-zero.
            log_error "'$script_name' failed. Continuing with the next script."
        fi
    done

    echo -e "
${GREEN}All selected scripts execution completed.${NC}"
    read -p "Press Enter to return to the menu..."
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
        "Configs Only (Sync dotfiles)"
        "Setup Quickshell (Clone/Sync Zenith-Shell for Quickshell)"
        "Setup Extra Assets (Animations and Wallpapers)"
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
            echo -e "
${GREEN}Press Enter to return to the menu...${NC}"
            read -r
            ;;
        5)
            setup_extra_assets
            echo -e "
${GREEN}Press Enter to return to the menu...${NC}"
            read -r
            ;;
        6) run_specific_script || true ;;
        7) log_step "Exiting. Have a great day!"; exit 0 ;;
    esac
done
