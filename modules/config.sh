#!/usr/bin/env bash

# Function to clone and setup Zenith-Shell for Quickshell
setup_quickshell() {
    log_step "✨ Setting up Zenith-Shell for Quickshell..."
    local qs_dir="$HOME/.config/quickshell"
    mkdir -p "$qs_dir"
    if [[ ! -d "$qs_dir/.git" ]]; then
        # Default to the canonical repo, but allow override if user wants
        git clone https://www.github.com/zaeemali272/zenith-shell.git "$qs_dir" || log_error "Failed to clone zenith-shell"
    else
        pushd "$qs_dir" >/dev/null && git pull && popd >/dev/null || log_warn "Failed to update zenith-shell"
    fi
}

# Function to setup extra themes
setup_extra_themes() {
    if [[ "$SKIP_THEMES" -eq 1 ]]; then
        log "Skipping extra themes as per flag."
        return
    fi

    log_step "🎨 Setting up Dynamic Materia Dark theme..."
    local theme_url="https://github.com/zaeemali272/dynamic-materia-dark.git"
    local theme_name="dynamic-materia-dark"
    local theme_path="$DOTS_DIR/$theme_name"
    local themes_dest="$DOTS_DIR/.themes"

    if [[ ! -d "$theme_path" ]]; then
        log "Cloning $theme_name..."
        git clone "$theme_url" "$theme_path" || { log_error "Failed to clone theme repo"; return; }
    else
        log "Updating $theme_name..."
        pushd "$theme_path" >/dev/null && git pull && popd >/dev/null
    fi

    log "Copying theme contents into $themes_dest/$theme_name..."
    mkdir -p "$themes_dest/$theme_name"
    # Using trailing slash on source and dest to ensure contents sync correctly
    rsync -av --exclude=".git" "$theme_path/" "$themes_dest/$theme_name/"
    log_success "Theme setup complete."
}

# Function to optimize ZRAM (Perfection/Speed)
setup_zram() {
    log_step "🚀 Configuring ZRAM for lightning speed..."
    sudo pacman -S --needed --noconfirm zram-generator || { log_error "Failed to install zram-generator"; return; }
    
    local zram_conf="/etc/systemd/zram-generator.conf"
    if [[ -f "$zram_conf" ]]; then
        log_warn "Existing zram configuration found. Backing up to $zram_conf$BACKUP_SUFFIX"
        sudo cp "$zram_conf" "$zram_conf$BACKUP_SUFFIX"
    fi

    cat <<'EOF' | sudo tee "$zram_conf" >/dev/null
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
    sudo systemctl daemon-reload && sudo systemctl start /dev/zram0
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
    
    setup_extra_themes

    local sync_option="backup"
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

    local rsync_args="-avh"
    if [[ "$sync_option" == "backup" ]]; then
        rsync_args="$rsync_args --backup --suffix=$BACKUP_SUFFIX"
    elif [[ "$sync_option" == "skip" ]]; then
        rsync_args="$rsync_args --ignore-existing"
    fi

    # Sync .config
    if [[ -d "$DOTS_DIR/.config" ]]; then
        mkdir -p "$HOME/.config"
        # Sync standard configs
        rsync $rsync_args --exclude ".git" --exclude "README.md" --exclude "install.sh" "$DOTS_DIR/.config/" "$HOME/.config/"
        
        # Explicitly ensure zenith-installer is synced if it exists (for post-boot UI)
        if [[ -d "$DOTS_DIR/.config/zenith-installer" ]]; then
            mkdir -p "$HOME/.config/zenith-installer"
            rsync $rsync_args "$DOTS_DIR/.config/zenith-installer/" "$HOME/.config/zenith-installer/"
        fi
    else
        log_warn ".config directory not found in $DOTS_DIR"
    fi
    
    # Sync .themes
    if [[ -d "$DOTS_DIR/.themes" ]]; then
        mkdir -p "$HOME/.themes"
        rsync $rsync_args "$DOTS_DIR/.themes/" "$HOME/.themes/"
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
    log_step "🚀 Setting up post-boot installer service..."
    local service_name="zenith-post-boot.service"
    local service_src="$DOTS_DIR/.config/systemd/user/$service_name"
    local service_dest="$HOME/.config/systemd/user/$service_name"
    local post_boot_script="$HOME/.config/hypr/post_boot.sh"

    # Ensure post_boot.sh is executable
    if [[ -f "$post_boot_script" ]]; then
        chmod +x "$post_boot_script"
    fi

    # 1. Systemd Service (Legacy/Fallback)
    if [[ -f "$service_src" ]]; then
        mkdir -p "$(dirname "$service_dest")"
        cp "$service_src" "$service_dest"
        systemctl --user daemon-reload
        systemctl --user enable "$service_name"
        log "Post-boot systemd service enabled."
    fi

    # 2. Hyprland Autostart (More reliable for minimal install)
    mkdir -p "$HOME/.config/hypr"
    echo "exec-once = $post_boot_script" > "$HOME/.config/hypr/autostart_once.conf"
    log_success "Post-boot autostart configured for Hyprland."
}
