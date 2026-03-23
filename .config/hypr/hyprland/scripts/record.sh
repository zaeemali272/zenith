#!/usr/bin/env bash

set -e

STATE_FILE="/tmp/wf-recorder-state"

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

getaudiooutput() {
    pactl list sources | grep 'Name' | grep 'monitor' | awk '{print $2}' | head -n1
}

getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

VIDEO_DIR="$(xdg-user-dir VIDEOS)"
[ "$VIDEO_DIR" = "$HOME" ] && VIDEO_DIR="$HOME/Videos"
mkdir -p "$VIDEO_DIR"
cd "$VIDEO_DIR"

# STOP recording if already running
if pgrep wf-recorder > /dev/null; then
    pkill wf-recorder

    FILE=$(cat "$STATE_FILE" 2>/dev/null || true)
    rm -f "$STATE_FILE"

    ACTION=$(notify-send \
        -i /usr/share/icons/OneUI/scalable/apps/screenshooter.svg \
        -a Recorder \
        -A "play=Play" \
        -A "folder=Open Folder" \
        "Recording stopped" \
        "$(basename "$FILE")")

    case "$ACTION" in
        play)
            xdg-open "$FILE"
            ;;
        folder)
            xdg-open "$VIDEO_DIR"
            ;;
    esac

    exit 0
fi

# START recording
FILE="recording_$(getdate).mp4"
echo "$VIDEO_DIR/$FILE" > "$STATE_FILE"

notify-send \
    -i /usr/share/icons/OneUI/scalable/apps/screenshooter.svg \
    -a Recorder \
    -h string:x-canonical-private-synchronous:record \
    "Recording started" \
    "$FILE"

case "$1" in
    --fullscreen-sound)
        wf-recorder -o "$(getactivemonitor)" \
            --pixel-format yuv420p \/usr/share/icons/OneUI/scalable/apps/screenshooter.svg
            --audio="$(getaudiooutput)" \
            -f "$FILE" &
        ;;
    --fullscreen)
        wf-recorder -o "$(getactivemonitor)" \
            --pixel-format yuv420p \
            -f "$FILE" &
        ;;
    *)
        region=$(slurp) || {
            notify-send -a Recorder "Recording cancelled"
            rm -f "$STATE_FILE"
            exit 1
        }
        wf-recorder \
            --pixel-format yuv420p \
            --geometry "$region" \
            -f "$FILE" &
        ;;
esac

disown

