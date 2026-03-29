#!/usr/bin/env bash

# Function to read from packages.json using jq
get_list() {
    local group=$1
    local source=$2
    local json_file="$DOTS_DIR/pkgs/packages.json"
    
    if ! command -v jq &>/dev/null; then
        log_error "jq is not installed! Cannot read package list."
        return 1
    fi

    if [[ -f "$json_file" ]]; then
        # Use jq to get the array for the group and source, then convert to space-separated string
        local pkgs=$(jq -r --arg g "$group" --arg s "$source" '.[$g][$s][]' "$json_file" 2>/dev/null | xargs)
        echo "$pkgs"
    else
        log_error "packages.json not found at $json_file!"
        echo ""
    fi
}

retry_pacman() {
    local packages=("$@")
    local max_attempts=3
    local attempt=1
    local delay=2

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
    
    # If we reach here, all attempts failed
    log_error "Failed to install after $max_attempts attempts: ${packages[*]}"
    return 1 # Skip this batch
}

install_pkgs() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return
    
    # Strict Filter: Only keep packages that are NOT already installed
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        else
            log "Package '$pkg' is already installed. Skipping."
        fi
    done

    [[ ${#to_install[@]} -eq 0 ]] && return

    local batch_size=15
    local total=${#to_install[@]}
    local processed=0
    
    for ((i=0; i<total; i+=batch_size)); do
        local batch=("${to_install[@]:i:batch_size}")
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

    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! yay -Qi "$pkg" &>/dev/null && ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        else
            log "AUR/Pacman package '$pkg' already exists. Skipping."
        fi
    done

    [[ ${#to_install[@]} -eq 0 ]] && return

    local total=${#to_install[@]}
    local current=0
    local max_aur_retries=3 # Limit retries for AUR packages

    for pkg in "${to_install[@]}"; do
        local attempt=1
        local success=false
        while (( attempt <= max_aur_retries )); do
            log_step "Installing AUR: $pkg (Attempt $attempt/$max_aur_retries)"
            # Use env to ensure yay is found and execute command
            if env PATH="/usr/bin:/usr/local/bin:/bin:/sbin" /usr/bin/yay -S --needed --noconfirm "$pkg"; then
                log_success "Installed AUR: $pkg"
                success=true
                break # Exit inner while loop if successful
            else
                log_warn "Attempt $attempt failed for AUR package: $pkg"
                ((attempt++))
                sleep 2 # Wait a bit before retrying
            fi
        done

        if ! $success; then
            log_error "Failed to install AUR package '$pkg' after $max_aur_retries attempts. Skipping."
            # No need to prompt, just skip.
        fi

        current=$((current + 1))
        show_progress $current $total "AUR Packages"
    done
}

install_group() {
    local group=$1
    log "Checking package group: $group"
    
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
    if has_run "minimal_packages_installed"; then
        log_success "Minimal packages already installed. Skipping."
        return
    fi

    # Only sync databases once per install session, skip full system upgrade (-u)
    if ! has_run "system_synced"; then
        log_step "🔄 Syncing system databases..."
        sudo pacman -Sy --noconfirm || log_warn "System sync failed, continuing anyway..."
        mark_done "system_synced"
    fi

    # 1. Install script essentials and YAY first
    log_step "📦 Installing YAY and system essentials..."
    sudo pacman -S --needed --noconfirm jq rsync git base-devel || log_error "Failed to install essentials."
    ensure_yay || log_error "Failed to install yay. AUR packages will fail."

    # 2. Graphical Core and System Components
    # Note: Priorities like thunar/vlc are inside 'core' group in packages.json
    install_group "core"
    install_group "drivers"

    # Hardware-specific packages from detection
    if [ ${#HARDWARE_PKGS[@]} -gt 0 ]; then
        log_step "🔧 Installing hardware-specific packages..."
        install_pkgs "${HARDWARE_PKGS[@]}"
    fi

    # Install quickshell for the post-boot UI
    install_aur "quickshell-git"

    mark_done "minimal_packages_installed"
}

install_remaining_packages() {
    log_step "🚀 Ensuring all Zenith packages are installed..."
    
    # 1. Ensure yay is present (critical for post-boot)
    ensure_yay || log_error "Failed to install yay. AUR packages will fail."

    # 2. Core & Drivers (Verify these are complete)
    install_group "core"
    install_group "drivers"

    # 3. Hardware-specific (Verify)
    if [ ${#HARDWARE_PKGS[@]} -gt 0 ]; then
        install_pkgs "${HARDWARE_PKGS[@]}"
    fi

    # 4. Optional components based on flags
    if [[ "${SKIP_FONTS:-0}" -eq 0 ]]; then install_group "fonts"; fi
    if [[ "${SKIP_GAMING:-0}" -eq 0 ]]; then install_group "gaming"; fi
    if [[ "${SKIP_THEMES:-0}" -eq 0 ]]; then install_group "themes"; fi
    if [[ "${SKIP_RECOMMENDED:-0}" -eq 0 ]]; then install_group "recommended"; fi
    
    # 5. AUR & Extras
    install_group "aur"
    if [[ "${SKIP_EXTRAS:-0}" -eq 0 ]]; then install_group "extras"; fi

    mark_done "remaining_packages_installed"
}

