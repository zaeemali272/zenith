#!/bin/bash

# 1. Create the local helper directory structure
echo "Creating XFCE helper directories..."
mkdir -p ~/.local/share/xfce4/helpers
mkdir -p ~/.config/xfce4

# 2. Create the Kitty helper definition
echo "Generating Kitty terminal helper..."
cat <<EOF > ~/.local/share/xfce4/helpers/kitty.desktop
[Desktop Entry]
Version=1.0
Icon=kitty
Type=X-XFCE-Helper
Name=kitty
X-XFCE-Category=TerminalEmulator
X-XFCE-Commands=kitty
X-XFCE-CommandsWithParameter=kitty "%s"
EOF

# 3. Force Thunar to use Kitty via helpers.rc
echo "Setting Kitty as the default TerminalEmulator..."
echo "TerminalEmulator=kitty" > ~/.config/xfce4/helpers.rc

# 4. Ensure xfconf (if running) knows about the change
if command -v xfconf-query &> /dev/null; then
    echo "Updating xfconf properties..."
    xfconf-query -c xfce4-helpers -p /TerminalEmulator -n -t string -s kitty 2>/dev/null || true
fi

# 5. Restart Thunar to apply changes
echo "Restarting Thunar..."
thunar -q || true
sleep 1
nohup thunar >/dev/null 2>&1 &
disown

echo "Done! Thunar should now open Kitty correctly."
