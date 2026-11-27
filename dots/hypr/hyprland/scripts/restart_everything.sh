#!/usr/bin/env bash
set -euo pipefail

# Restart active shell cleanly
if command -v zenith >/dev/null 2>&1; then
    zenith shell restart >/dev/null 2>&1 || true
elif [ -x "$HOME/.config/quickshell/launch.sh" ]; then
    "$HOME/.config/quickshell/launch.sh" restart >/dev/null 2>&1 || true
elif command -v quickshell >/dev/null 2>&1; then
    pkill -15 -f '^quickshell( |$)' 2>/dev/null || true
    sleep 0.2
    pkill -9 -f '^quickshell( |$)' 2>/dev/null || true
    nohup quickshell -d >/dev/null 2>&1 &
fi

# Ensure wallpaper daemon (awww) is active and current wallpaper is restored
if command -v awww >/dev/null 2>&1; then
    if ! awww query >/dev/null 2>&1; then
        nohup awww-daemon >/dev/null 2>&1 &
        sleep 0.3
    fi
    awww restore >/dev/null 2>&1 || true
    if [ -f "$HOME/.config/current_wallpaper.txt" ]; then
        current_wall="$(cat "$HOME/.config/current_wallpaper.txt" 2>/dev/null || true)"
        if [ -n "$current_wall" ] && [ -f "$current_wall" ]; then
            awww img --resize=crop "$current_wall" >/dev/null 2>&1 || true
        fi
    fi
fi

# Restart desktop portal services cleanly if systemctl exists (preserving audio & Bluetooth connections)
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal 2>/dev/null || true
fi

# Reload Hyprland configuration and state
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send -i system-restart -a "Hyprland" "Desktop services reloaded" 2>/dev/null || true
fi