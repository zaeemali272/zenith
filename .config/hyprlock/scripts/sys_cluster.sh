#!/bin/bash

# --- CONFIGURATION ---
ICON_WIFI=""
ICON_BT=""
ICON_POWER="󰓅"

# --- HELPERS ---
get_wifi() {
    ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    [ -z "$ssid" ] && echo "Off" || echo "$ssid"
}

get_bluetooth() {
    if command -v bluetoothctl >/dev/null; then
        status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
        if [ "$status" == "yes" ]; then
            devices=$(bluetoothctl devices Connected | wc -l)
            [ "$devices" -gt 0 ] && echo "On ($devices)" || echo "On"
        else
            echo "Off"
        fi
    else
        echo "N/A"
    fi
}

get_power_profile() {
    if command -v powerprofilesctl >/dev/null; then
        profile=$(powerprofilesctl get)
        echo "$profile"
    else
        echo "N/A"
    fi
}

# --- OUTPUT ---
case "$1" in
    --wifi) echo "$ICON_WIFI $(get_wifi)" ;;
    --bt) echo "$ICON_BT $(get_bluetooth)" ;;
    --power) echo "$ICON_POWER $(get_power_profile)" ;;
    *) echo "Usage: $0 --wifi | --bt | --power" ;;
esac
