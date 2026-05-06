#!/usr/bin/env bash

# Zenith Theme Management System
# Supports --autoselect and falls back to current_wallpaper.txt

if [[ -f "../modules/ui.sh" ]]; then
    source "../modules/ui.sh"
else
    log_step() { echo -e "\e[1;34m[STEP]\e[0m $*"; }
    log() { echo -e "  ➜ $*"; }
    log_success() { echo -e "\e[1;32m[OK]\e[0m $*"; }
    log_error() { echo -e "\e[1;31m[ERR]\e[0m $*"; }
fi

# Check for --autoselect flag
AUTOSELECT=false
if [[ "$1" == "--autoselect" ]]; then
    AUTOSELECT=true
    shift 
fi

# Determine Wallpaper Path
WALLPAPER=$1
WALL_CACHE="$HOME/.config/current_wallpaper.txt"

if [[ -z "$WALLPAPER" ]]; then
    if [[ -f "$WALL_CACHE" ]]; then
        WALLPAPER=$(cat "$WALL_CACHE")
        log "📖 No path provided, using cached: $WALLPAPER"
    else
        log_error "No wallpaper provided and $WALL_CACHE not found."
        exit 1
    fi
fi

# Final check if the file from the text file actually exists
if [[ ! -f "$WALLPAPER" ]]; then
    log_error "Wallpaper file does not exist: $WALLPAPER"
    exit 1
fi

SOURCE_COLOR=$2

log_step "🎨 Generating theme from $WALLPAPER..."
[[ "$AUTOSELECT" == "true" ]] && log "✨ Autoselect enabled: picking first color match."

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if command -v matugen &> /dev/null; then
    MATUGEN_CMD="matugen image \"$WALLPAPER\" --config \"zenith/.config/matugen/config.toml\""
    
   if [[ -n "$SOURCE_COLOR" ]]; then
        (cd "$PROJECT_ROOT" && eval "$MATUGEN_CMD --color \"$SOURCE_COLOR\"")
    elif [[ "$AUTOSELECT" == "true" ]]; then
        # 'saturation' ensures it works in non-interactive shells
        (cd "$PROJECT_ROOT" && eval "$MATUGEN_CMD --prefer=saturation")
    else
        (cd "$PROJECT_ROOT" && eval "$MATUGEN_CMD")
    fi
    log_success "Matugen generated templates successfully."
else
    log_error "Matugen is not installed."
    exit 1
fi

# Reloading components
log_step "🔄 Reloading components..."
hyprctl reload
if pgrep -x quickshell &> /dev/null; then
    killall quickshell
    # Launching back the shell (ensure paths match your repo structure)
    (cd "$PROJECT_ROOT/zenith-shell" && ./launch.sh wallpaperSelector &> /dev/null &)
fi

killall -USR1 kitty 2>/dev/null
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
sleep 0.1
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

log_success "Zenith theme updated!"