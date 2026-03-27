#!/bin/bash

# --- Configuration ---
UCA_FILE="$HOME/.config/Thunar/uca.xml"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Ensure the UCA file exists with basic XML structure if missing
if [ ! -f "$UCA_FILE" ]; then
    mkdir -p "$(dirname "$UCA_FILE")"
    echo '<?xml version="1.0" encoding="UTF-8"?><actions></actions>' > "$UCA_FILE"
fi

# --- 1. Create swww Wallpaper Logic ---
cat << 'EOF' > "$BIN_DIR/set-swww.sh"
#!/bin/bash
pgrep -x swww-daemon > /dev/null || swww-daemon &
swww img "$1" --transition-type grow --transition-pos center
echo "$1" > "$HOME/.cache/current_wallpaper"
EOF
chmod +x "$BIN_DIR/set-swww.sh"

# --- 2. Create Terminal Logic (Open Kitty Here) ---
# We use kitty because you are on Hyprland, but you can swap to 'exo-open' if preferred
cat << 'EOF' > "$BIN_DIR/open-terminal.sh"
#!/bin/bash
kitty --working-directory "$1" &
EOF
chmod +x "$BIN_DIR/open-terminal.sh"

# --- 3. Function to add Thunar Action safely ---
add_thunar_action() {
    local id="$1"
    local name="$2"
    local cmd="$3"
    local icon="$4"
    local patterns="$5"
    local type_flag="$6" # e.g., "<image-files/>" or "<directories/>"

    if grep -q "$id" "$UCA_FILE"; then
        echo "Action '$name' already exists. Skipping."
    else
        sed -i "/<\/actions>/i \
    <action>\n\
        <icon>$icon</icon>\n\
        <name>$name</name>\n\
        <unique-id>$id</unique-id>\n\
        <command>$cmd</command>\n\
        <description>$name</description>\n\
        <patterns>$patterns</patterns>\n\
        $type_flag\n\
    </action>" "$UCA_FILE"
        echo "Added '$name' to Thunar."
    fi
}

# --- 4. Add the actions to the XML ---
# Set as Wallpaper Action
add_thunar_action \
    "swww-wallpaper-action" \
    "Set as wallpaper" \
    "$BIN_DIR/set-swww.sh %f" \
    "preferences-desktop-wallpaper" \
    "*" \
    "<image-files/>"

# Open Terminal Here Action
add_thunar_action \
    "open-terminal-action" \
    "Open Terminal Here" \
    "$BIN_DIR/open-terminal.sh %f" \
    "utilities-terminal" \
    "*" \
    "<directories/>"

# --- 5. Clean up Thunar ---
# Hide the default XFCE wallpaper plugin
mkdir -p ~/.local/share/Thunar/sendto
echo "NoDisplay=true" > ~/.local/share/Thunar/sendto/thunar-wallpaper-plugin.desktop

echo "Done! Restarting Thunar..."
thunar -q || true
sleep 1
nohup thunar >/dev/null 2>&1 &
disown