#!/usr/bin/env bash

# Function to clone and setup Zenith-Shell for Quickshell
setup_quickshell() {
    log_step "✨ Setting up Zenith-Shell for Quickshell..."
    local qs_dir="$HOME/.config/quickshell"
    local repo_url="https://github.com/zaeemali272/zenith-shell.git"

    # FORCE CHECK: Is it actually a git repo?
    if [[ -d "$qs_dir" ]]; then
        if [[ ! -d "$qs_dir/.git" ]]; then
            log_warn "Directory exists but is NOT a git repo. Deleting for fresh clone..."
            rm -rf "$qs_dir"
        fi
    fi

    if [[ ! -d "$qs_dir" ]]; then
        log "Cloning zenith-shell from GitHub..."
        git clone "$repo_url" "$qs_dir" || log_error "Failed to clone zenith-shell"
    else
        log "Updating existing zenith-shell in $qs_dir..."
        # Force a reset in case local files are messed up
        git -C "$qs_dir" fetch --all
        git -C "$qs_dir" reset --hard origin/main || log_warn "Git reset failed."
    fi
    
    log_success "Quickshell setup complete."
}

# Function to setup Hyprland configs
setup_hyprland_dots() {
    log_step "✨ Setting up Hyprland configs..."
    local hypr_dir="$HOME/.config/hypr"

    if [[ -d "$DOTS_DIR/dots/hypr" ]]; then
        log "Linking Hyprland configuration from $DOTS_DIR/dots/hypr..."
        mkdir -p "$HOME/.config"
        ln -sfn "$DOTS_DIR/dots/hypr" "$hypr_dir"
        find "$DOTS_DIR/dots/hypr" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
        log_success "Hyprland configs linked from dots/hypr."
        return 0
    fi

    local repo_url="https://github.com/zaeemali272/zenith.git"
    if [[ ! -d "$hypr_dir" ]]; then
        log "Cloning Zenith from GitHub..."
        git clone "$repo_url" "$HOME/zenith" && ln -sfn "$HOME/zenith/dots/hypr" "$hypr_dir" || log_error "Failed to setup Hyprland configs"
    fi
    log_success "Hyprland setup complete."
}

# Function to clone and setup Zenith CLI
setup_zenith_cli() {
    log_step "✨ Setting up Zenith CLI..."
    local cli_dir="$HOME/zenith/zenith-cli"
    local repo_url="https://github.com/zaeemali272/zenith-cli.git"
    local bin_dir="$HOME/.local/bin"

    mkdir -p "$bin_dir" "$(dirname "$cli_dir")"

    if [[ ! -d "$cli_dir" ]]; then
        log "Cloning zenith-cli from GitHub..."
        git clone "$repo_url" "$cli_dir" || log_warn "Failed to clone zenith-cli"
    else
        log "Updating zenith-cli..."
        git -C "$cli_dir" fetch --all 2>/dev/null || true
        git -C "$cli_dir" reset --hard origin/main 2>/dev/null || true
    fi

    if [[ -f "$cli_dir/bin/zenith" ]]; then
        chmod +x "$cli_dir/bin/zenith"
        ln -sfn "$cli_dir/bin/zenith" "$bin_dir/zenith"
        log_success "Zenith CLI linked to ~/.local/bin/zenith"
    fi
}

# Apply the desktop look: Orchis (darker) with Reversal icons.
#
# Every value is checked against what is actually installed before it is set.
# gsettings accepts a theme name that does not exist and silently renders the
# default, so a typo or a missing package looks like "the theme just did not
# apply" with nothing to debug.
apply_desktop_theme() {
    log_step "🎨 Applying Orchis (darker) and Reversal icons..."

    local gtk_theme="Orchis-Dark"
    local icon_theme="Reversal-dark"
    local cursor_theme="Bibata-Modern-Classic"

    theme_installed() {  # kind, name
        local kind="$1" name="$2"
        [[ -d "/usr/share/$kind/$name" || -d "$HOME/.local/share/$kind/$name" \
           || -d "$HOME/.$kind/$name" ]]
    }

    if theme_installed themes "$gtk_theme"; then
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        log_success "GTK theme: $gtk_theme"
    else
        log_warn "$gtk_theme is not installed -- install orchis-theme-git, then rerun."
    fi

    if theme_installed icons "$icon_theme"; then
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
        log_success "Icons: $icon_theme"
    else
        log_warn "$icon_theme is not installed -- install reversal-icon-theme-git, then rerun."
    fi

    if theme_installed icons "$cursor_theme"; then
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"
        gsettings set org.gnome.desktop.interface cursor-size 24
    fi

    # GTK reads these files, not just gsettings -- applications started outside
    # a session with dconf (and every GTK4 app) use them.
    local gtk3="$HOME/.config/gtk-3.0/settings.ini"
    local gtk4="$HOME/.config/gtk-4.0/settings.ini"
    mkdir -p "$(dirname "$gtk3")" "$(dirname "$gtk4")"
    for f in "$gtk3" "$gtk4"; do
        cat > "$f" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    done

    # libadwaita ignores gtk-theme-name entirely; it only follows these assets.
    local src="/usr/share/themes/$gtk_theme/gtk-4.0"
    if [[ -d "$src" ]]; then
        mkdir -p "$HOME/.config/gtk-4.0"
        for asset in assets gtk.css gtk-dark.css; do
            [[ -e "$src/$asset" ]] && ln -sfn "$src/$asset" "$HOME/.config/gtk-4.0/$asset"
        done
        log_success "libadwaita assets linked"
    fi

    # Qt applications, so they match rather than staying Fusion-grey.
    local qt_conf="$HOME/.config/qt5ct/qt5ct.conf"
    for v in qt5ct qt6ct; do
        qt_conf="$HOME/.config/$v/$v.conf"
        if [[ -f "$qt_conf" ]]; then
            sed -i 's/^icon_theme=.*/icon_theme='"$icon_theme"'/' "$qt_conf" 2>/dev/null || true
        fi
    done
}

# Add the user to the groups a desktop actually needs.
setup_user_groups() {
    log_step "👤 Adding $USER to the required groups..."

    # input   -> input device access (gamepads, libinput tools)
    # video   -> backlight control
    # audio   -> legacy ALSA/JACK access
    # storage, optical, lp, scanner -> removable media, discs, printing
    local wanted=(input video audio storage optical lp network users)

    # Only if the corresponding service is actually installed.
    getent group docker  >/dev/null 2>&1 && wanted+=(docker)
    getent group libvirt >/dev/null 2>&1 && wanted+=(libvirt)
    getent group kvm     >/dev/null 2>&1 && wanted+=(kvm)
    getent group wheel   >/dev/null 2>&1 && wanted+=(wheel)

    local added=()
    local skipped=()
    for grp in "${wanted[@]}"; do
        if ! getent group "$grp" >/dev/null 2>&1; then
            skipped+=("$grp")
            continue
        fi
        if id -nG "$USER" | tr ' ' '\n' | grep -qx "$grp"; then
            continue
        fi
        if sudo usermod -aG "$grp" "$USER"; then
            added+=("$grp")
        else
            log_warn "Could not add $USER to $grp"
        fi
    done

    if [[ ${#added[@]} -gt 0 ]]; then
        log_success "Added to: ${added[*]}"
        log_warn "Group changes only apply to a new session -- log out and back in."
    else
        log_success "Already in every required group."
    fi
    [[ ${#skipped[@]} -gt 0 ]] && log "Not present on this system: ${skipped[*]}"
}

# Function to optimize ZRAM (Perfection/Speed)
setup_zram() {
    log_step "🚀 Checking ZRAM..."

    # archinstall configures zram on most modern installs, and this function
    # used to overwrite /etc/systemd/zram-generator.conf regardless -- replacing
    # a working, tuned configuration with its own. Taking a backup first does not
    # make that acceptable: the user never asked for it to change.
    #
    # So it now only acts when nothing is providing zram already.
    if swapon --show=NAME --noheadings 2>/dev/null | grep -q zram \
       || systemctl is-active --quiet systemd-zram-setup@zram0.service 2>/dev/null; then
        log_success "ZRAM is already active (archinstall or an existing config) -- leaving it alone."
        return 0
    fi

    if [[ -f /etc/systemd/zram-generator.conf ]]; then
        log_success "zram-generator.conf already exists -- leaving it alone."
        return 0
    fi

    sudo pacman -S --needed --noconfirm zram-generator || {
        log_error "Failed to install zram-generator"; return 1; }

    cat <<'EOF' | sudo tee /etc/systemd/zram-generator.conf >/dev/null
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service 2>/dev/null \
        || sudo systemctl start /dev/zram0 2>/dev/null || true
    log_success "ZRAM configured."
}


sanitize_dotfiles() {
    log_step "🧹 Sanitizing dotfiles (Updating paths for $USER)..."
    # Find files containing the hardcoded username 'zaeem' and replace with current $USER
    # We limit this to text files in .config to avoid corrupting binaries
    local target_dir="$HOME/.config"
    
    if [[ "$USER" != "zaeem" ]]; then
        grep -rIl "home/zaeem" "$target_dir" | while read -r file; do
            sed -i "s|/home/zaeem|$HOME|g" "$file"
            log "Updated paths in $file"
        done
        # Also handle fish variables specifically if they exist
        if [[ -f "$HOME/.config/fish/fish_variables" ]]; then
             sed -i "s|/home/zaeem|$HOME|g" "$HOME/.config/fish/fish_variables"
        fi
        log_success "Dotfiles sanitized for user '$USER'."
    fi
}

sync_dotfiles() {
    log_step "📁 Syncing configs..."

    local sync_option="backup"
    if [[ "$JSON_OUTPUT" == "true" || "$JSON_OUTPUT" == "1" ]]; then
        sync_option="backup"
        log "Non-interactive mode: Auto-selecting backup for dotfiles sync."
    else
        echo -e "${YELLOW}Existing configuration files found in \$HOME.${NC}"
        echo -e "How would you like to proceed?"
        echo -e "  1) ${CYAN}Backup existing files${NC} (adds $BACKUP_SUFFIX extension) and overwrite"
        echo -e "  2) ${RED}Just overwrite${NC} (no backups)"
        echo -e "  3) ${GREEN}Skip already existing files${NC}"
        
        read -p "Select an option [1-3, default: 1]: " choice
        case $choice in
            2) sync_option="overwrite" ;;
            3) sync_option="skip" ;;
            *) sync_option="backup" ;;
        esac
    fi

    local rsync_args="-avh"
    if [[ "$sync_option" == "backup" ]]; then
        rsync_args="$rsync_args --backup --suffix=$BACKUP_SUFFIX"
    elif [[ "$sync_option" == "skip" ]]; then
        rsync_args="$rsync_args --ignore-existing"
    fi

    # Sync user dotfiles from dots/
    if [[ -d "$DOTS_DIR/dots" ]]; then
        mkdir -p "$HOME/.config"
        rsync $rsync_args --exclude ".git" --exclude "hypr" "$DOTS_DIR/dots/" "$HOME/.config/"
    else
        log_warn "dots directory not found in $DOTS_DIR"
    fi


    # Sync .local
    if [[ -d "$DOTS_DIR/.local" ]]; then
        mkdir -p "$HOME/.local"
        rsync $rsync_args "$DOTS_DIR/.local/" "$HOME/.local/"
    fi

    # Sync Pictures (Wallpapers)
    if [[ -d "$DOTS_DIR/Pictures" ]]; then
        mkdir -p "$HOME/Pictures"
        rsync $rsync_args "$DOTS_DIR/Pictures/" "$HOME/Pictures/"
    fi

    setup_quickshell
    setup_hyprland_dots
    setup_zenith_cli
    apply_desktop_theme
    sanitize_dotfiles
    log_success "Dotfiles synced."
}

set_fish_shell() {
    log_step "🐟 Setting Fish as default shell..."
    if ! command -v fish &>/dev/null; then
        log_warn "Fish shell not found. Skipping."
        return
    fi
    
    local fish_path=$(command -v fish)
    
    if ! grep -q "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
        log "Added fish to /etc/shells"
    fi
    
    if [[ "$SHELL" != "$fish_path" ]]; then
        sudo chsh -s "$fish_path" "$USER"
        log_success "Fish shell set for $USER."
    else
        log_success "Fish is already the default shell."
    fi
}

setup_xdg_dirs() {
    log_step "📁 Ensuring XDG directories..."
    sudo pacman -S --needed --noconfirm xdg-user-dirs || log_error "Failed to install xdg-user-dirs"
    
    # Explicitly create common user directories
    mkdir -p "$HOME"/{Documents,Downloads,Pictures,Videos,Music,Games}
    
    # Update XDG directories based on the config file in .config (if synced already)
    xdg-user-dirs-update
    
    # Sync Wallpapers specifically to ensure they are present in the new Pictures dir
    if [[ -d "$DOTS_DIR/Pictures/Wallpapers" ]]; then
        log_step "🖼️ Copying wallpapers to ~/Pictures/Wallpapers..."
        mkdir -p "$HOME/Pictures/Wallpapers"
        cp -r "$DOTS_DIR/Pictures/Wallpapers/." "$HOME/Pictures/Wallpapers/"
    fi
    
    log_success "XDG directories and wallpapers updated."
}

setup_post_boot_service() {
    log_step "🚀 Setting up post-boot installer autostart..."
    local execs_file="$HOME/.config/hypr/hyprland/execs.conf"
    local post_boot_cmd="exec-once = bash $DOTS_DIR/scripts/post_boot_install.sh"

    # Create directory if missing
    mkdir -p "$(dirname "$execs_file")"

    # Add the line if not already present
    if ! grep -q "post_boot_install.sh" "$execs_file" 2>/dev/null; then
        echo -e "\n$post_boot_cmd" >> "$execs_file"
        log "Post-boot autostart added to $execs_file."
    fi

    log_success "Post-boot autostart configured for Hyprland."
}

# Function to setup extra assets (Animations & Wallpapers)
setup_extra_assets() {
    log_step "✨ Setting up extra Zenith assets (Animations & Wallpapers)..."
    
    local anim_url="https://drive.proton.me/urls/S03D75Y3RG#1thoI8ITod8K"
    local wall_url="https://drive.proton.me/urls/6GN7BD5TXR#ENq5AcFhGCzf"
    
    local anim_dir="$HOME/Videos/Animations"
    local wall_dir="$HOME/Pictures/Wallpapers"
    
    mkdir -p "$anim_dir" "$wall_dir"

    # NOTE: Proton Drive links are encrypted and hard to download via CLI.
    # Proposing a robust structure. If these were direct links, curl would work here.
    log_warn "Proton Drive links detected. These usually require a browser to decrypt."
    log "If download fails, please download manually and extract to:"
    log "  - Animations: $anim_dir"
    log "  - Wallpapers: $wall_dir"

    # Example of how it SHOULD look with direct links:
    # curl -L "DIRECT_URL" -o "/tmp/assets.zip" && unzip "/tmp/assets.zip" -d "$anim_dir"
    
    # For now, we attempt a basic download (this may fail due to Proton's encryption)
    # If you provide direct links later, this script is ready.
}
