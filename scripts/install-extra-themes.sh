#!/usr/bin/env bash
# Zenith Script: Install Dynamic Materia Dark Theme
# Clones the theme and copies it to the .themes directory for syncing.

# Ensure we are in the project root
if [[ ! -f "install.sh" ]]; then
    echo "❌ Please run this script from the root of the zenith repository."
    exit 1
fi

# Load UI if available for pretty logging
if [[ -f "modules/ui.sh" ]]; then
    source "modules/ui.sh"
else
    # Fallback logging
    log_step() { echo -e "\e[1;34m[STEP]\e[0m $*"; }
    log() { echo -e "  ➜ $*"; }
    log_success() { echo -e "\e[1;32m[OK]\e[0m $*"; }
    log_error() { echo -e "\e[1;31m[ERR]\e[0m $*"; }
fi

THEME_URL="https://github.com/zaeemali272/dynamic-materia-dark/releases/download/theme/dynamic-materia-dark.tar.gz"
THEME_NAME="dynamic-materia-dark"
THEMES_DEST="$HOME/.themes"

log_step "🎨 Installing Dynamic Materia Dark Theme..."

# Ensure ~/.themes exists
mkdir -p "$THEMES_DEST"

# Download and Extract
log "Downloading $THEME_NAME from GitHub Releases..."
if curl -L "$THEME_URL" -o "/tmp/$THEME_NAME.tar.gz"; then
    log "Extracting theme to $THEMES_DEST..."
    tar -xzf "/tmp/$THEME_NAME.tar.gz" -C "$THEMES_DEST"
    rm "/tmp/$THEME_NAME.tar.gz"
    log_success "Dynamic Materia Dark theme installed successfully in $THEMES_DEST."
else
    log_error "Failed to download the theme asset."
    exit 1
fi

# Apply Icon Theme
log_step "🖼️ Checking Icon Theme..."
CURRENT_ICONS=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
if [[ "$CURRENT_ICONS" != "OneUI-dark" ]]; then
    log "Applying OneUI-dark icon theme..."
    gsettings set org.gnome.desktop.interface icon-theme "OneUI-dark"
    log_success "OneUI-dark icon theme applied."
else
    log "OneUI-dark icon theme is already set."
fi
