#!/bin/bash

# --- CONFIGURATION ---
# Maximum characters to display before scrolling starts
MAX_LEN=25
# Padding between the repeated text in the scroll
PADDING="       "

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --arturl | --artist | --length | --album | --source | --status"
    exit 1
fi

# Function to get metadata using playerctl
get_metadata() {
    key=$1
    playerctl metadata --format "{{ $key }}" 2>/dev/null
}

# Function to create a scrolling/carousel effect
# Takes the string as input
carousel() {
    local text="$1"
    local len=${#text}

    if [ "$len" -le "$MAX_LEN" ]; then
        echo "$text"
    else
        # Use system seconds to determine the shift position
        local total_text="$text$PADDING"
        local total_len=${#total_text}
        local offset=$(( ($(date +%s)* 3) % total_len ))

        # Double the text to allow seamless looping
        local loop="$total_text$total_text"
        echo "${loop:$offset:$MAX_LEN}"
    fi
}

get_source_info() {
    raw_player=$(playerctl -l | head -n 1)
    status=$(playerctl status 2>/dev/null)

    if [ -z "$status" ]; then
        echo "No Player Running"
        return
    fi

    # Clean the player name
    clean_name=$(echo "$raw_player" | cut -d'.' -f1)

    case "$clean_name" in
        "firefox") echo "Firefox 󰈹" ;;
        "spotify") echo "Spotify " ;;
        "chromium") echo "YT Music " ;;
        "vlc") echo "VLC 󰕼" ;;
        "kdeconnect")
                    # This captures ONLY the device name and strips everything else
                    device=$(kdeconnect-cli -a 2>/dev/null | grep ":" | head -n 1 | sed 's/^- //' | cut -d':' -f1)

                    if [ -n "$device" ]; then
                        echo "$device "
                    else
                        echo "Phone "
                    fi
                    ;;
    esac
}

# Parse the argument
case "$1" in
--title)
    title=$(get_metadata "xesam:title")
    if [ -z "$title" ]; then
        echo "Nothing Playing"
    else
        carousel "$title"
    fi
    ;;
--arturl)
    url=$(get_metadata "mpris:artUrl")
    if [ -z "$url" ]; then
        echo ""
    else
        if [[ "$url" == file://* ]]; then
            url=${url#file://}
        fi
        echo "$url"
    fi
    ;;
--artist)
    artist=$(get_metadata "xesam:artist")
    if [ -z "$artist" ]; then
        echo "Unknown Artist"
    else
        carousel "$artist"
    fi
    ;;
--length)
    length=$(get_metadata "mpris:length")
    if [ -z "$length" ]; then
        echo ""
    else
        # Convert length from microseconds to MM:SS
        total_seconds=$(( length / 100000000 ))
        printf "%02d:%02d\n" $((total_seconds/60)) $((total_seconds%60))
    fi
    ;;
--status)
    status=$(playerctl status 2>/dev/null)
    if [[ $status == "Playing" ]]; then
        echo "󰎆"
    elif [[ $status == "Paused" ]]; then
        echo "󱑽"
    else
        echo "󰝛"
    fi
    ;;
--album)
    album=$(get_metadata "xesam:album")
    if [[ -n "$album" ]]; then
        echo "$album"
    else
        echo "No Album"
    fi
    ;;
--source)
    get_source_info
    ;;
*)
    echo "Invalid option: $1"
    exit 1
    ;;
esac
