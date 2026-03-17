#!/usr/bin/env bash

# Function to read from packages.json using jq
get_list() {
    local group=$1
    local source=$2
    local json_file="$DOTS_DIR/pkgs/packages.json"
    
    if [[ -f "$json_file" ]]; then
        # Use jq to get the array for the group and source, then convert to space-separated string
        local pkgs=$(jq -r ".[\"$group\"].$source[]" "$json_file" 2>/dev/null | xargs)
        echo "$pkgs"
    else
        log_error "packages.json not found!"
        echo ""
    fi
}

retry_pacman() {
    local packages=("$@")
    local max_attempts=3
    local attempt=1
    local delay=2

    while true; do
        attempt=1
        while (( attempt <= max_attempts )); do
            log_step "Installing (attempt $attempt/$max_attempts): ${packages[*]}"
            if sudo pacman -S --needed --noconfirm --noprogressbar "${packages[@]}"; then
                log_success "Successfully installed: ${packages[*]}"
                return 0
            else
                log_warn "Attempt $attempt failed."
                ((attempt++))
                [[ $attempt -le $max_attempts ]] && sleep $delay
            fi
        done
        
        log_error "Failed to install after $max_attempts attempts: ${packages[*]}"
        local options=("Retry" "Skip (Try with yay/AUR)" "Quit Installation")
        ask_choice "Pacman failed to install these packages. What would you like to do?" "${options[@]}"
        case $MENU_CHOICE in
            0) continue ;;
            1) return 1 ;;
            2) log_step "Exiting..."; exit 1 ;;
        esac
    done
}

install_pkgs() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return
    
    local batch_size=15
    local total=${#pkgs[@]}
    local processed=0
    
    for ((i=0; i<total; i+=batch_size)); do
        local batch=("${pkgs[@]:i:batch_size}")
        if ! retry_pacman "${batch[@]}"; then
            log_warn "Batch failed in pacman. Attempting AUR fallback for these packages..."
            install_aur "${batch[@]}"
        fi
        processed=$((i + batch_size))
        if [ $processed -gt $total ]; then processed=$total; fi
        show_progress $processed $total "Pacman Packages"
    done
}

ensure_yay() {
    if ! command -v yay &>/dev/null; then
        log_step "📦 Installing yay (AUR helper)..."
        local tmp_dir=$(mktemp -d)
        sudo pacman -S --needed --noconfirm base-devel git || { log_error "Failed to install base-devel for yay"; return 1; }
        git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin" || { log_error "Failed to clone yay-bin"; return 1; }
        pushd "$tmp_dir/yay-bin" >/dev/null
        makepkg -si --noconfirm || { log_error "Failed to build/install yay"; popd >/dev/null; return 1; }
        popd >/dev/null
        rm -rf "$tmp_dir"
        log_success "yay installed successfully."
    fi
    return 0
}

install_aur() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return
    
    local total=${#pkgs[@]}
    local current=0

    for pkg in "${pkgs[@]}"; do
        while true; do
            log_step "Installing AUR: $pkg"
            if yay -S --needed --noconfirm "$pkg"; then
                log_success "Installed AUR: $pkg"
                break
            else
                log_error "Failed AUR: $pkg"
                local options=("Retry" "Skip" "Quit Installation")
                ask_choice "AUR installation failed for '$pkg'. What would you like to do?" "${options[@]}"
                case $MENU_CHOICE in
                    0) continue ;;
                    1) break ;;
                    2) log_step "Exiting..."; exit 1 ;;
                esac
            fi
        done
        current=$((current + 1))
        show_progress $current $total "AUR Packages"
    done
}

install_group() {
    local group=$1
    local pacman_pkgs=($(get_list "$group" "pacman"))
    local aur_pkgs=($(get_list "$group" "aur"))

    if [ ${#pacman_pkgs[@]} -gt 0 ]; then
        log_step "📦 Installing $group (pacman)..."
        install_pkgs "${pacman_pkgs[@]}"
    fi

    if [ ${#aur_pkgs[@]} -gt 0 ]; then
        log_step "✨ Installing $group (AUR)..."
        install_aur "${aur_pkgs[@]}"
    fi
}

install_minimal_packages() {
    log_step "🔄 Updating system databases..."
    sudo pacman -Syu --noconfirm || log_warn "System update failed, continuing anyway..."

    # Ensure AUR helper is available early
    ensure_yay || log_warn "Failed to install yay. AUR packages might fail."

    # Core system components
    install_group "core"
    install_group "drivers"
    
    # Hardware-specific packages from detection
    if [ ${#HARDWARE_PKGS[@]} -gt 0 ]; then
        log_step "🔧 Installing hardware-specific packages..."
        install_pkgs "${HARDWARE_PKGS[@]}"
    fi

    # Install quickshell for the post-boot UI
    log_step "✨ Installing Quickshell for post-boot UI..."
    install_aur "quickshell-git"
}

install_remaining_packages() {
    # Optional components based on flags
    [[ "$SKIP_FONTS" -eq 0 ]] && install_group "fonts"
    [[ "$SKIP_GAMING" -eq 0 ]] && install_group "gaming"
    [[ "$SKIP_THEMES" -eq 0 ]] && install_group "themes"
    [[ "$SKIP_RECOMMENDED" -eq 0 ]] && install_group "recommended"
    
    # Remaining packages
    install_group "aur"
    [[ "$SKIP_EXTRAS" -eq 0 ]] && install_group "extras"
}
