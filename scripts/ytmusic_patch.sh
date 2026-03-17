#!/usr/bin/env bash
# ytmusic_patch.sh — Patch YouTube Music config and inject custom CSS

CONFIG_DIR="$HOME/.config/YouTube Music"
CONFIG_FILE="$CONFIG_DIR/config.json"
CSS_FILE="$CONFIG_DIR/custom-style.css"

# --- Ensure directory exists ---
mkdir -p "$CONFIG_DIR"

# Create a minimal CSS placeholder first
echo "/* Loading YouTube Music CSS... */" > "$CSS_FILE"

# Then overwrite with the full CSS
cat > "$CSS_FILE" <<'EOF'
/* --- YouTube Music Player Bar Custom Style --- */
#player-bar-background { background-color: transparent !important; }
#progress-bar.ytmusic-player-bar { left: 0px !important; width: 100.6% !important; margin: 0px !important; }
#sliderContainer.tp-yt-paper-slider { margin-left: 0px !important; }
ytmusic-player-bar { background-color: rgba(0, 0, 0, 0.85) !important; backdrop-filter: blur(6px) !important; border-top: 1px solid rgba(255, 255, 255, 0.1) !important; }
ytmusic-player-bar tp-yt-paper-progress, ytmusic-player-bar .middle-controls, ytmusic-player-bar .left-controls, ytmusic-player-bar .right-controls { background: transparent !important; }
ytmusic-nav-bar, ytmusic-app-layout #nav-bar-background { border-bottom: none !important; box-shadow: none !important; background-color: transparent !important; }
ytmusic-app-layout #guide-spacer, ytmusic-app-layout #nav-bar-divider { background: transparent !important; border: none !important; box-shadow: none !important; }
#mini-guide-background { border: none !important; }
ytmusic-nav-bar { display: flex !important; justify-content: flex-start !important; align-items: center !important; background: transparent !important; box-shadow: none !important; border: none !important; transition: background-color 0.3s ease, backdrop-filter 0.3s ease, transform 0.3s ease !important; backdrop-filter: none !important; }
ytmusic-nav-bar > *:not(.left-content) { opacity: 0 !important; pointer-events: none !important; transition: opacity 0.3s ease !important; }
ytmusic-nav-bar .left-content { display: flex !important; align-items: center !important; padding-left: 12px !important; }
ytmusic-nav-bar .left-content > * { margin-right: 0.5rem !important; }
ytmusic-nav-bar:hover { background-color: rgba(0, 0, 0, 0.6) !important; backdrop-filter: blur(10px) !important; }
ytmusic-nav-bar:hover > *:not(.left-content) { opacity: 1 !important; pointer-events: auto !important; }
EOF

# --- Patch JSON safely (requires jq) ---
if command -v jq &>/dev/null; then
  if [[ -f "$CONFIG_FILE" ]]; then
    ESCAPED_CSS_FILE=$(printf '%s\n' "$CSS_FILE" | sed 's/\\/\\\\/g; s/"/\\"/g')

    jq --arg css "$ESCAPED_CSS_FILE" \
      '.options.tray = true
       | .options.appVisible = false
       | .options.hideMenuWarned = true
       | .options.removeUpgradeButton = true
       | .options.hideMenu = true
       | .options.removeUpgradeButton = true
       | .options.hideMenu = true
       | .customCSS = $css
       | .options.themes = [$css]' \
      "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "✅ Patched $CONFIG_FILE successfully."
  else
    echo "⚠️  No config.json found, creating new minimal one."
    cat > "$CONFIG_FILE" <<EOF
{
  "options": {
    "tray": true,
    "appVisible": false,
    "hideMenuWarned": true,
    "removeUpgradeButton": true,
    "hideMenu": true,
    "themes": ["$CSS_FILE"]
  },
  "visualTweaks": {
    "removeUpgradeButton": true,
    "hideMenu": true
  },
  "customCSS": "$CSS_FILE"
}
EOF
  fi
else
  echo "❌ jq not found. Install it first: sudo pacman -S jq"
  exit 1
fi

echo "✅ CSS injected at: $CSS_FILE"
echo "✅ Config patched at: $CONFIG_FILE"
echo "➡️  Restart YouTube Music for changes to apply."
