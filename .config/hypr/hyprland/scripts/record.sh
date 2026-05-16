#!/usr/bin/env bash

STATE_FILE="/tmp/recording-state"

getdate() {
    date '+%Y-%m-%d_%H-%M-%S'
}

# Finds your actual physical microphone input
getmicinput() {
    pactl get-default-source 2>/dev/null || \
    pactl list sources short | awk '/input/ {print $2}' | head -n1
}

# Robust way to grab the system sound loopback stream
getsystemsound() {
    DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
    if [ -n "$DEFAULT_SINK" ]; then
        echo "${DEFAULT_SINK}.monitor"
    else
        pactl list sources short | awk '/monitor/ {print $2}' | head -n1
    fi
}

getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

VIDEO_DIR="$HOME/Videos/Recordings"
mkdir -p "$VIDEO_DIR"

# --- STOP RECORDING LOGIC ---
# Check if either tool is active using loose pgrep matching
if pgrep -f "wl-screenrec" > /dev/null || pgrep -f "gpu-screen-recorder" > /dev/null; then
    
    # Use killall as you confirmed this successfully signals them on your setup
    killall -SIGINT wl-screenrec 2>/dev/null || true
    killall -SIGINT gpu-screen-recorder 2>/dev/null || true

    # Give the encoders time to finish writing the file containers safely
    sleep 0.6

    FILE_PATH=$(cat "$STATE_FILE" 2>/dev/null || true)
    rm -f "$STATE_FILE"

    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        echo -n "$FILE_PATH" | wl-copy
        
        # Fires the action handler to your Quickshell notificationItem.qml
        ACTION=$(notify-send \
            -i screenshooter \
            -a Recorder \
            -A "default=Open Video" \
            -A "folder=Open Folder" \
            "Recording stopped & copied to clipboard" \
            "$(basename "$FILE_PATH")")

        case "$ACTION" in
            default)
                xdg-open "$FILE_PATH"
                ;;
            folder)
                xdg-open "$VIDEO_DIR"
                ;;
        esac
    fi
    exit 0
fi

# Clear out any stale state files left behind from previous crashes
rm -f "$STATE_FILE"

# --- START RECORDING LOGIC ---
FILE="recording_$(getdate).mp4"
FULL_PATH="$VIDEO_DIR/$FILE"
echo "$FULL_PATH" > "$STATE_FILE"

notify-send \
    -i screenshooter \
    -a Recorder \
    -h string:x-canonical-private-synchronous:record \
    "Recording started" \
    "$FILE"

case "$1" in
    --fullscreen-all)
        gpu-screen-recorder \
            -w "$(getactivemonitor)" \
            -f 60 \
            -a "$(getsystemsound)|$(getmicinput)" \
            -o "$FULL_PATH" &
        ;;
    --fullscreen-sound)
        gpu-screen-recorder \
            -w "$(getactivemonitor)" \
            -f 60 \
            -a "$(getsystemsound)" \
            -o "$FULL_PATH" &
        ;;
    --fullscreen)
        gpu-screen-recorder \
            -w "$(getactivemonitor)" \
            -f 60 \
            -o "$FULL_PATH" &
        ;;
    --region|*)
        region=$(slurp) || {
            notify-send -a Recorder "Recording cancelled"
            rm -f "$STATE_FILE"
            exit 0
        }
        wl-screenrec \
            -g "$region" \
            -f "$FULL_PATH" &
        ;;
esac

disown