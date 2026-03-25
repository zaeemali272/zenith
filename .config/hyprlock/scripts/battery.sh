#!/bin/bash

# Get the current battery percentage
battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)
# Get the battery status
battery_status=$(cat /sys/class/power_supply/BAT0/status)

# Function to generate a solid Pango bar
# We use a large number of block characters to make it look smooth
generate_pango_bar() {
    local percent=$1
    local width=24 # Adjusted to fit the 320px width at font size 14
    local filled=$(( (percent * width) / 100 ))
    
    # We only return the filled part; the shape provides the background
    local bar="<span foreground='#141414'>"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="</span>"
    echo "$bar"
}

# Function to get icon
get_icon() {
    local percent=$1
    local status=$2
    
    if [ "$status" = "Charging" ]; then
        echo "󱐋"
        return
    fi
    
    if [ $percent -ge 95 ]; then echo "󰁹";
    elif [ $percent -ge 80 ]; then echo "󰂂";
    elif [ $percent -ge 70 ]; then echo "󰂁";
    elif [ $percent -ge 60 ]; then echo "󰂀";
    elif [ $percent -ge 50 ]; then echo "󰁿";
    elif [ $percent -ge 40 ]; then echo "󰁾";
    elif [ $percent -ge 30 ]; then echo "󰁽";
    elif [ $percent -ge 20 ]; then echo "󰁼";
    elif [ $percent -ge 10 ]; then echo "󰁻";
    else echo "󰁺"; fi
}

case "$1" in
    --icon)
        get_icon "$battery_percentage" "$battery_status"
        ;;
    --percent)
        echo "$battery_percentage%"
        ;;
    --pango-bar)
        generate_pango_bar "$battery_percentage"
        ;;
    --status)
        if [ "$battery_status" = "Charging" ]; then
            echo "Charging..."
        elif [ "$battery_status" = "Full" ]; then
            echo "Charged"
        else
            echo "Discharging"
        fi
        ;;
    *)
        echo "$battery_percentage% $(get_icon "$battery_percentage" "$battery_status")"
        ;;
esac
