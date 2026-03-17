#!/usr/bin/env bash
# set_browser_prefs.sh
# Configures Zen Browser (or Firefox fallback) with custom prefs and Zen mods.
# Safely merges customization state from prefs.js into user.js.
# ✅ Automatically detects latest Zen profile.

set -euo pipefail

echo "🔧 Setting browser preferences and Zen mods..."

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.bak_$(date +%Y%m%d%H%M%S)"
        cp "$file" "$backup"
        echo "🗂️  Backup created: $backup"
    fi
}

merge_ui_state() {
    local prefs_file="$1"
    local userjs="$2"
    local layout_json="$3"

    if ! command -v jq &>/dev/null; then
        echo "❌ 'jq' not found. Please install it first."
        exit 1
    fi

    # Extract current UI state from prefs.js (if exists)
    local current_state
    current_state=$(grep 'browser.uiCustomization.state' "$prefs_file" 2>/dev/null | \
        sed -E 's/^user_pref\("browser\.uiCustomization\.state", "(.*)"\);$/\1/' | \
        sed 's/\\"/"/g' || echo '{}')

    # Merge custom placements
    local merged
    merged=$(jq -cn \
        --argjson current "$current_state" \
        --argjson custom "$layout_json" \
        '$current * {placements: $custom.placements}')

    # Escape back to Firefox-friendly JSON
    local escaped
    escaped=$(printf '%s' "$merged" | jq -aRs . | sed 's/^"//;s/"$//')

    echo "user_pref(\"browser.uiCustomization.state\", \"$escaped\");" >> "$userjs"
}

COMMON_PREFS='
user_pref("media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled", true);
'

ZEN_LAYOUT=$(cat <<'EOF'
{
  "placements": {
    "widget-overflow-fixed-list": [],
    "unified-extensions-area": [],
    "nav-bar": [
      "back-button",
      "home-button",
      "forward-button",
      "urlbar-container",
      "bookmarks-menu-button"
    ],
    "toolbar-menubar": ["menubar-items"],
    "TabsToolbar": ["tabbrowser-tabs"],
    "PersonalToolbar": ["personal-bookmarks"],
    "zen-sidebar-top-buttons": [],
    "zen-sidebar-foot-buttons": [
      "downloads-button",
      "panic-button",
      "history-panelmenu",
      "logins-button",
      "preferences-button",
      "fxa-toolbar-menu-button"
    ]
  }
}
EOF
)

ZEN_MODS_EXPORT="$HOME/Hyprland-dots/zen-mods-export.json"
ZEN_DIR="$HOME/.zen"
FIREFOX_DIR="$HOME/.mozilla/firefox"

#########################
# Zen Browser
#########################
if [ -f "$ZEN_DIR/profiles.ini" ]; then
    echo "🌐 Zen Browser detected."

    # ✅ Detect most recently modified Zen profile
    latest_profile=$(grep '^Path=' "$ZEN_DIR/profiles.ini" | cut -d= -f2 | while read -r p; do
        echo "$ZEN_DIR/$p"
    done | xargs -I{} bash -c 'echo "$(stat -c "%Y %n" "{}")"' | sort -nr | head -n1 | cut -d' ' -f2-)

    if [ -n "$latest_profile" ]; then
        echo "🧠 Using latest Zen profile: $latest_profile"
        prefs_file="$latest_profile/prefs.js"
        userjs="$latest_profile/user.js"
        zenmods="$latest_profile/zen-themes.json"

        mkdir -p "$latest_profile"
        [ -f "$userjs" ] || touch "$userjs"
        backup_file "$userjs"

        echo "$COMMON_PREFS" > "$userjs"

        # --- Zen-specific preferences ---
        echo 'user_pref("zen.theme.content-element-separation", 1);' >> "$userjs"
        echo 'user_pref("zen.view.compact.enable-at-startup", true);' >> "$userjs"
        echo 'user_pref("zen.view.compact.hide-toolbar", true);' >> "$userjs"
        echo 'user_pref("zen.view.sidebar-expanded", false);' >> "$userjs"
        echo 'user_pref("widget.wayland.popups.use-native", false);' >> "$userjs"

        merge_ui_state "$prefs_file" "$userjs" "$ZEN_LAYOUT"

        echo "✅ Updated Zen preferences for profile: $(basename "$latest_profile")"

        if [ -f "$ZEN_MODS_EXPORT" ]; then
            backup_file "$zenmods"
            cp "$ZEN_MODS_EXPORT" "$zenmods"
            echo "🎨 Applied Zen mods from: $ZEN_MODS_EXPORT"
        else
            echo "⚠️ No Zen mods export found at $ZEN_MODS_EXPORT"
        fi
    else
        echo "⚠️ No Zen profiles found in profiles.ini"
    fi
else
    echo "⚠️ Zen Browser not found. Skipping..."
fi

#########################
# Firefox (fallback)
#########################
if [ -d "$FIREFOX_DIR" ]; then
    profile=$(ls "$FIREFOX_DIR" | grep '\.default-release' | head -n1 || true)
    if [ -n "$profile" ]; then
        full_path="$FIREFOX_DIR/$profile"
        prefs_file="$full_path/prefs.js"
        userjs="$full_path/user.js"
        mkdir -p "$full_path"
        [ -f "$userjs" ] || touch "$userjs"
        backup_file "$userjs"

        echo "$COMMON_PREFS" > "$userjs"
        merge_ui_state "$prefs_file" "$userjs" "$ZEN_LAYOUT"

        echo "✅ Updated Firefox preferences for profile: $profile"
    else
        echo "⚠️ No Firefox default profile found. Skipping..."
    fi
else
    echo "⚠️ Firefox not found. Skipping..."
fi

echo "🎉 All done!"

