#!/bin/bash

# Configuration Sync Script for Zenith
# Links files from ~/Documents/Dots/zenith/.config/ to ~/.config/

DOTS_DIR="$HOME/Documents/Dots/zenith/.config"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$CONFIG_DIR/old_backups"

# List of directories to link
DIRS=(
    "anyrun"
    "fish"
    "fusuma"
    "gtk-3.0"
    "gtk-4.0"
    "hypr"
    "hyprlock"
    "kitty"
    "Kvantum"
    "matugen"
    "mpv"
    "qt5ct"
    "qt6ct"
    "systemd"
    "wlogout"
)

echo "🔄 Starting config sync..."
mkdir -p "$BACKUP_DIR"

for dir in "${DIRS[@]}"; do
    TARGET="$CONFIG_DIR/$dir"
    SOURCE="$DOTS_DIR/$dir"

    if [[ ! -d "$SOURCE" ]]; then
        echo "⚠️  Source directory $SOURCE does not exist. Skipping."
        continue
    fi

    # If it's a directory and not a symlink, back it up
    if [[ -d "$TARGET" && ! -L "$TARGET" ]]; then
        echo "📦 Backing up existing $dir to $BACKUP_DIR..."
        mv "$TARGET" "$BACKUP_DIR/"
    fi

    # Create symlink if it doesn't exist or is broken
    if [[ ! -e "$TARGET" || -L "$TARGET" ]]; then
        ln -snf "$SOURCE" "$TARGET"
        echo "🔗 Linked $dir -> $SOURCE"
    fi
done

echo "✅ Sync completed!"
