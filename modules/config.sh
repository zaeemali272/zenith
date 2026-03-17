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
    
    # Sync .config
    if [[ -d "$DOTS_DIR/.config" ]]; then
        mkdir -p "$HOME/.config"
        rsync -avh --backup --suffix="$BACKUP_SUFFIX" --exclude ".git" --exclude "README.md" --exclude "install.sh" "$DOTS_DIR/.config/" "$HOME/.config/"
    else
        log_warn ".config directory not found in $DOTS_DIR"
    fi
    
    # Sync .themes
    if [[ -d "$DOTS_DIR/.themes" ]]; then
        mkdir -p "$HOME/.themes"
        rsync -avh "$DOTS_DIR/.themes/" "$HOME/.themes/"
    fi

    # Sync .local
    if [[ -d "$DOTS_DIR/.local" ]]; then
        mkdir -p "$HOME/.local"
        rsync -avh "$DOTS_DIR/.local/" "$HOME/.local/"
    fi

    # Sync Pictures (Wallpapers)
    if [[ -d "$DOTS_DIR/Pictures" ]]; then
        mkdir -p "$HOME/Pictures"
        rsync -avh "$DOTS_DIR/Pictures/" "$HOME/Pictures/"
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
    xdg-user-dirs-update
    log_success "XDG directories updated."
}

setup_post_boot_service() {
    log_step "🚀 Setting up post-boot installer service..."
    local service_name="zenith-post-boot.service"
    local service_src="$DOTS_DIR/.config/systemd/user/$service_name"
    local service_dest="$HOME/.config/systemd/user/$service_name"

    if [[ -f "$service_src" ]]; then
        mkdir -p "$(dirname "$service_dest")"
        cp "$service_src" "$service_dest"
        systemctl --user daemon-reload
        systemctl --user enable "$service_name"
        log_success "Post-boot service enabled."
    else
        log_error "Post-boot service file not found at $service_src"
    fi
}
