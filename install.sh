#!/usr/bin/env bash
set -euo pipefail

# --- Initial Setup ---
DOTS_DIR="$(pwd)"
export DOTS_DIR

# --- Distro Check: NixOS Routing ---
if [[ -f /etc/NIXOS ]] || command -v nixos-rebuild &>/dev/null; then
    echo "❄️  Detected NixOS! Zenith on NixOS is managed declaratively via Flakes."
    echo ""
    echo "To rebuild your system configuration:"
    echo "    zenith rebuild"
    echo "or:"
    echo "    sudo nixos-rebuild switch --flake .#$(hostname)"
    echo ""
    echo "To run health checks and diagnostics:"
    echo "    zenith doctor"
    echo ""
    exit 0
fi

# --- Load Modules Early (For Colors and UI) ---
if [[ -d "modules" ]]; then
    for f in modules/arch/*.sh modules/*.sh; do
        [[ -f "$f" ]] && source "$f"
    done
else
    echo "❌ 'modules' directory not found. Please run from the zenith/ root."
    exit 1
fi

# --- Error Handling ---
SUDO_KEEP_ALIVE_PID=0

stop_sudo_keepalive() {
    if [[ ${SUDO_KEEP_ALIVE_PID:-0} -ne 0 ]]; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
        SUDO_KEEP_ALIVE_PID=0
    fi
}

error_handler() {
    local exit_code=$1
    local line_no=$2
    # Ensure cleanup is triggered
    cleanup
    if command -v log_error &>/dev/null; then
        log_error "An error occurred at line $line_no (Exit Code: $exit_code)"
    else
        echo "ERR: An error occurred at line $line_no (Exit Code: $exit_code)"
    fi
    echo -e "${RED:-}The script encountered an issue and had to stop.${NC:-}"
}
trap 'error_handler $? $LINENO' ERR

cleanup() {
    stop_sudo_keepalive
    rm -f /tmp/zenith_temp_* 2>/dev/null
}
trap cleanup EXIT INT TERM

# --- Sudo Keep-Alive ---
init_sudo() {
    log_step "🔐 Authenticating sudo..."
    sudo -v < /dev/tty || { log_error "Sudo authentication failed."; exit 1; }
    
    # Automatically terminates when the parent script exits
    (
        while kill -0 $$ 2>/dev/null; do
            sudo -n true
            sleep 50
        done
    ) &
    SUDO_KEEP_ALIVE_PID=$!
    log_success "Sudo keep-alive started (PID: $SUDO_KEEP_ALIVE_PID)"
}

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
export SKIP_GAMING=1
export SKIP_THEMES=0
export SKIP_RECOMMENDED=0
export SKIP_EXTRAS=0
export SKIP_FONTS=0
export SKIP_SCRIPTS=0
export AUTO_INSTALL=0
export JSON_OUTPUT=0
export RUN_QUICKSHELL=0
export RUN_CONFIGS=0
export RUN_NEW_PKGS=0
export SKIP_XDG=0

# Parse Arguments
for arg in "$@"; do
    case $arg in
        --gaming) export SKIP_GAMING=0 ;;
        --no-gaming) export SKIP_GAMING=1 ;;
        --no-themes) export SKIP_THEMES=1 ;;
        --no-recommended) export SKIP_RECOMMENDED=1 ;;
        --no-extras) export SKIP_EXTRAS=1 ;;
        --no-fonts) export SKIP_FONTS=1 ;;
        --no-scripts) export SKIP_SCRIPTS=1 ;;
        --skip-xdg) export SKIP_XDG=1 ;;
        --auto|--unattended) export AUTO_INSTALL=1 ;;
        --json) export JSON_OUTPUT=1 ;;
        --quickshell) export RUN_QUICKSHELL=1 ;;
        --configs) export RUN_CONFIGS=1 ;;
        --new-pkgs) export RUN_NEW_PKGS=1 ;;

        # Rerunning after a failure is the normal case, so it is the default:
        # completed steps are skipped and only what is missing or failed runs.
        --force|--redo)  export ZENITH_FORCE=1 ;;
        --status)        export SHOW_STATUS=1 ;;
        --reset)         export RESET_STATE=1 ;;
        -h|--help)       export SHOW_HELP=1 ;;
    esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then
    cat <<'USAGE'
zenith installer

  ./install.sh                 install, or resume -- steps already completed are
                               skipped, failed ones are retried
  ./install.sh --status        show what is done and what failed, change nothing
  ./install.sh --force         redo every step, including completed ones
  ./install.sh --reset         forget all recorded state and start over

  --gaming                     include optional gaming packages (wine, winetricks)
  --no-themes --no-recommended --no-extras --no-fonts
  --no-scripts --skip-xdg      leave those parts out
  --auto                       no prompts

A step that fails does not stop the run. It is recorded, the rest continues, and
the summary at the end lists what to retry -- just run ./install.sh again.
USAGE
    exit 0
fi

if [[ "${RESET_STATE:-0}" -eq 1 ]]; then
    rm -f "$HOME/.zenith_install_state" "$HOME/.zenith_install_failed"
    echo "Installer state cleared. The next run starts from scratch."
    exit 0
fi

if [[ "${SHOW_STATUS:-0}" -eq 1 ]]; then
    show_status
    exit 0
fi

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
    run_step "setup_zram" "Checking ZRAM" setup_zram
    log_success "System tuning complete."
}

# --- Pre-Network Fix ---
pre_network_fix() {
    log_step "💾 Checking network and installing essential tools..."
    
    # Install essentials first (if possible)
    # Using -n for non-interactive to avoid hanging if sudo fails
    if sudo -n pacman -S --needed --noconfirm nano rsync git jq >/dev/null 2>&1; then
        log_success "Essential tools installed."
    else
        log_warn "Could not install tools immediately. Checking network..."
    fi

    # Check internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "Internet connection detected. Skipping DNS override."
    else
        log_warn "No internet connection. Attempting to fix DNS..."
        # On a systemd-resolved or NetworkManager system /etc/resolv.conf is a
        # symlink into their runtime state. Writing through it replaces a
        # managed file with a static one, and DNS silently stops following the
        # network from then on -- so the symlink is preserved and the override
        # is written as a real file only after moving it aside.
        if [[ -L /etc/resolv.conf ]]; then
            log_warn "/etc/resolv.conf is a symlink to $(readlink -f /etc/resolv.conf)"
            log_warn "Replacing it temporarily; the original link is saved as /etc/resolv.conf.bak"
            sudo mv /etc/resolv.conf /etc/resolv.conf.bak
        elif [[ -f /etc/resolv.conf ]]; then
            sudo cp /etc/resolv.conf /etc/resolv.conf.bak
        fi
        echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
        DNS_OVERRIDDEN=1
        
        # Retry install
        sudo pacman -S --needed --noconfirm nano rsync git jq || log_error "Failed to install essential tools even after DNS fix."
    fi
}

# Put DNS back the way it was, if this installer changed it.
restore_dns() {
    [[ "${DNS_OVERRIDDEN:-0}" -eq 1 ]] || return 0
    if [[ -e /etc/resolv.conf.bak ]]; then
        sudo mv -f /etc/resolv.conf.bak /etc/resolv.conf
        log_success "Restored the original /etc/resolv.conf"
    else
        log_warn "DNS was overridden to 8.8.8.8/1.1.1.1 and no backup was found."
        log_warn "If your network manages DNS, remove /etc/resolv.conf and let it regenerate."
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

export CUSTOM_REMOVE_PKGS="${CUSTOM_REMOVE_PKGS:-}"
export CUSTOM_ADD_PKGS="${CUSTOM_ADD_PKGS:-}"

# --- Interactive Main Package Review ---
customize_packages() {
    local mode="${1:-minimal}"
    [[ -r /dev/tty ]] || return 0

    local main_terminal="kitty"
    local main_fm="thunar"
    local main_editor="zed"
    local main_media="mpv"
    local main_shell="fish, hyprland, quickshell-git"
    local main_browsers="zen-browser-bin, thorium-browser-bin"
    local main_apps="antigravity-bin, freedownloadmanager-bin, pear-desktop-bin, element-desktop"

    while true; do
        echo ""
        echo -e "${BOLD}${CYAN}📦 Main Packages ($mode install):${NC}"
        echo -e "  ${BOLD}Terminal:${NC}     $main_terminal"
        echo -e "  ${BOLD}File Manager:${NC} $main_fm"
        echo -e "  ${BOLD}Editor:${NC}       $main_editor"
        echo -e "  ${BOLD}Media:${NC}        $main_media"
        echo -e "  ${BOLD}Shell / WM:${NC}   $main_shell"
        if [[ "$mode" != "minimal" ]]; then
            echo -e "  ${BOLD}Browsers:${NC}     $main_browsers"
            echo -e "  ${BOLD}Apps:${NC}         $main_apps"
        fi
        [[ -n "${CUSTOM_REMOVE_PKGS// /}" ]] && echo -e "  ${YELLOW}Removed:${NC}      $CUSTOM_REMOVE_PKGS"
        [[ -n "${CUSTOM_ADD_PKGS// /}" ]] && echo -e "  ${GREEN}Added:${NC}        $CUSTOM_ADD_PKGS"
        echo ""
        echo -e "${BOLD}Do you want to change, remove, or add any packages?${NC}"
        echo "  [Enter] Continue with installation"
        echo "  [1] Change / swap a package (e.g. thunar -> dolphin)"
        echo "  [2] Remove package(s)"
        echo "  [3] Add package(s)"
        read -p "> " pkg_action </dev/tty || pkg_action=""

        case "$pkg_action" in
            ""|c|C|n|N)
                break
                ;;
            1)
                read -p "Package to replace: " old_pkg </dev/tty || old_pkg=""
                read -p "New package name: " new_pkg </dev/tty || new_pkg=""
                if [[ -n "$old_pkg" && -n "$new_pkg" ]]; then
                    CUSTOM_REMOVE_PKGS="$CUSTOM_REMOVE_PKGS $old_pkg"
                    CUSTOM_ADD_PKGS="$CUSTOM_ADD_PKGS $new_pkg"
                    export CUSTOM_REMOVE_PKGS CUSTOM_ADD_PKGS
                    log_success "Will replace '$old_pkg' with '$new_pkg'."
                fi
                ;;
            2)
                read -p "Package(s) to remove (space-separated): " rm_pkgs </dev/tty || rm_pkgs=""
                if [[ -n "$rm_pkgs" ]]; then
                    CUSTOM_REMOVE_PKGS="$CUSTOM_REMOVE_PKGS $rm_pkgs"
                    export CUSTOM_REMOVE_PKGS
                    log_success "Will skip: $rm_pkgs"
                fi
                ;;
            3)
                read -p "Package(s) to add (space-separated): " add_pkgs </dev/tty || add_pkgs=""
                if [[ -n "$add_pkgs" ]]; then
                    CUSTOM_ADD_PKGS="$CUSTOM_ADD_PKGS $add_pkgs"
                    export CUSTOM_ADD_PKGS
                    log_success "Will add: $add_pkgs"
                fi
                ;;
            *)
                log_warn "Invalid choice. Press Enter to continue or choose 1, 2, or 3."
                ;;
        esac
    done
}

# --- Feature Groups ---
minimal_install() {
    customize_packages "minimal"
    init_sudo
    pre_network_fix
    run_step "system_prep" "Preparing the system (mirrors)" system_prep
    run_step "system_tuning" "Tuning pacman and makepkg" system_tuning
    run_step "detect_hardware" "Detecting hardware" detect_hardware
    run_step "install_minimal_packages" "Installing core packages" install_minimal_packages
    run_step "setup_user_groups" "Adding you to the required groups" setup_user_groups
    run_step "sync_dotfiles" "Syncing dotfiles" sync_dotfiles
    run_step "set_fish_shell" "Setting fish as the shell" set_fish_shell
    run_step "setup_post_boot_service" "Installing the post-boot service" setup_post_boot_service
    run_step "setup_autologin" "Configuring autologin" setup_autologin

    print_summary || true
    installation_summary "Minimal"
    echo -e "
${YELLOW}${BOLD}Rebooting in 10s... (Press Ctrl+C to cancel)${NC}"
    sleep 10 && sudo reboot
}

full_install() {
    customize_packages "full"
    init_sudo
    pre_network_fix
    run_step "system_prep" "Preparing the system (mirrors)" system_prep
    run_step "system_tuning" "Tuning pacman and makepkg" system_tuning
    run_step "detect_hardware" "Detecting hardware" detect_hardware
    run_step "install_minimal_packages" "Installing core packages" install_minimal_packages
    run_step "install_remaining_packages" "Installing the remaining packages" install_remaining_packages
    run_step "setup_user_groups" "Adding you to the required groups" setup_user_groups
    run_step "sync_dotfiles" "Syncing dotfiles" sync_dotfiles
    if [[ "$SKIP_XDG" -eq 0 ]]; then
        run_step "setup_xdg_dirs" "Creating XDG directories" setup_xdg_dirs
    fi
    run_step "set_fish_shell" "Setting fish as the shell" set_fish_shell
    run_step "setup_system_services" "Enabling system services" setup_system_services
    bash scripts/power-profile-setup.sh || log_warn "Power profile setup failed."
    run_step "setup_autologin" "Configuring autologin" setup_autologin
    run_step "apply_desktop_theme" "Applying the desktop theme" apply_desktop_theme
    run_step "optimize_bootloader" "Optimising the bootloader" optimize_bootloader
    restore_dns
    
    print_summary || true
    installation_summary "Full"
    echo -e "
${YELLOW}${BOLD}Rebooting in 10s... (Press Ctrl+C to cancel)${NC}"
    sleep 10 && sudo reboot
}

packages_only() {
    customize_packages "packages"
    init_sudo
    run_step "system_prep" "Preparing the system (mirrors)" system_prep
    run_step "detect_hardware" "Detecting hardware" detect_hardware
    run_step "install_minimal_packages" "Installing core packages" install_minimal_packages
    run_step "install_remaining_packages" "Installing the remaining packages" install_remaining_packages
    log_success "Package installation complete."
}

configs_only() {
    run_step "setup_user_groups" "Adding you to the required groups" setup_user_groups
    run_step "sync_dotfiles" "Syncing dotfiles" sync_dotfiles
    if [[ "$SKIP_XDG" -eq 0 ]]; then
        run_step "setup_xdg_dirs" "Creating XDG directories" setup_xdg_dirs
    fi
    log_success "Configuration sync complete."
    run_step "apply_desktop_theme" "Applying the desktop theme" apply_desktop_theme
}

# --- Main Flow ---
if [[ "$RUN_QUICKSHELL" -eq 1 || "$RUN_CONFIGS" -eq 1 || "$RUN_NEW_PKGS" -eq 1 ]]; then
    log_step "🚀 Running specific tasks..."
    if [[ "$RUN_NEW_PKGS" -eq 1 ]]; then install_new_packages; fi
    if [[ "$RUN_CONFIGS" -eq 1 ]]; then configs_only; fi
    if [[ "$RUN_QUICKSHELL" -eq 1 ]]; then setup_quickshell; fi
    exit 0
fi

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
        "Packages Only (Install system and AUR packages)"
        "Configs Only (Sync dotfiles & apply theme)"
        "Setup Quickshell (Clone/Sync Zenith-Shell for Quickshell)"
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
            read -r </dev/tty
            ;;
        5) log_step "Exiting. Have a great day!"; exit 0 ;;
    esac

done
