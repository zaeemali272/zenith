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

DOTS_DIR="$(pwd)"
THEME_URL="https://github.com/zaeemali272/dynamic-materia-dark.git"
THEME_NAME="dynamic-materia-dark"
THEME_PATH="$DOTS_DIR/$THEME_NAME"
THEMES_DEST="$DOTS_DIR/.themes"

log_step "🎨 Installing Dynamic Materia Dark Theme..."

# Clone or Update
if [[ ! -d "$THEME_PATH" ]]; then
    log "Cloning $THEME_NAME from $THEME_URL..."
    git clone "$THEME_URL" "$THEME_PATH" || { log_error "Failed to clone theme repository."; exit 1; }
else
    log "Theme repository already exists. Pulling latest changes..."
    pushd "$THEME_PATH" >/dev/null && git pull && popd >/dev/null || log_warn "Failed to update theme repository."
fi

# Copy to .themes
log "Copying theme to $THEMES_DEST..."
mkdir -p "$THEMES_DEST"
cp -r "$THEME_PATH" "$THEMES_DEST/"

log_success "Dynamic Materia Dark theme is now staged in $THEMES_DEST and will be synced during installation."
