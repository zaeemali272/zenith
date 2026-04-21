#!/bin/bash

# A temporary file to store the last time the script ran
LOCK_FILE="/tmp/fusuma_music_lock"
# Cool-down period in seconds (e.g., 0.8 seconds)
INTERVAL=0.8

CUR_TIME=$(date +%s%N)

if [ -f "$LOCK_FILE" ]; then
    LAST_TIME=$(cat "$LOCK_FILE")
    # Calculate time difference in nanoseconds
    DIFF=$(( (CUR_TIME - LAST_TIME) / 1000000 ))
    # If less than 800ms has passed, exit without doing anything
    if [ "$DIFF" -lt 800 ]; then
        exit 0
    fi
fi

# Update the lock file with current time
echo "$CUR_TIME" > "$LOCK_FILE"

# Execute the media key using playerctl (recommended) or ydotool/xdotool
if [ "$1" == "next" ]; then
    playerctl next
elif [ "$1" == "prev" ]; then
    playerctl previous
fi
