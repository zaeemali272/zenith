#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/recording-state-$UID"
VIDEO_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$VIDEO_DIR"

getdate() {
    date '+%Y-%m-%d_%H-%M-%S'
}

getmicinput() {
    if command -v pactl >/dev/null 2>&1; then
        pactl get-default-source 2>/dev/null || \
        pactl list sources short 2>/dev/null | awk '/input/ {print $2}' | head -n1
    elif command -v wpctl >/dev/null 2>&1; then
        wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk -F'"' '/node.name/ {print $2}'
    fi
}

getsystemsound() {
    if command -v pactl >/dev/null 2>&1; then
        DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || true)
        if [ -n "$DEFAULT_SINK" ]; then
            echo "${DEFAULT_SINK}.monitor"
        else
            pactl list sources short 2>/dev/null | awk '/monitor/ {print $2}' | head -n1
        fi
    elif command -v wpctl >/dev/null 2>&1; then
        SINK=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/node.name/ {print $2}')
        if [ -n "$SINK" ]; then
            echo "${SINK}.monitor"
        fi
    fi
}

getactivemonitor() {
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || true
    fi
}

send_notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@" 2>/dev/null || true
    fi
}

# Stop recording if already running
if pidof wl-screenrec gpu-screen-recorder wf-recorder > /dev/null 2>&1; then
    pkill -SIGINT -x wl-screenrec 2>/dev/null || true
    pkill -SIGINT -x gpu-screen-recorder 2>/dev/null || true
    pkill -SIGINT -x wf-recorder 2>/dev/null || true
    sleep 0.6

    FILE_PATH=$(cat "$STATE_FILE" 2>/dev/null || true)
    rm -f "$STATE_FILE"

    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        if command -v wl-copy >/dev/null 2>&1; then
            echo -n "$FILE_PATH" | wl-copy || true
        fi
        send_notify \
            -i screenshooter \
            -a Recorder \
            "Recording stopped & copied to clipboard" \
            "$(basename "$FILE_PATH")"
    else
        send_notify -i screenshooter -a Recorder "Recording stopped"
    fi
    exit 0
fi

# Detect available recorder binary
RECORDER=""
if command -v wl-screenrec >/dev/null 2>&1; then
    RECORDER="wl-screenrec"
elif command -v gpu-screen-recorder >/dev/null 2>&1; then
    RECORDER="gpu-screen-recorder"
elif command -v wf-recorder >/dev/null 2>&1; then
    RECORDER="wf-recorder"
fi

if [ -z "$RECORDER" ]; then
    send_notify -i dialog-error -a Recorder "Recording failed" "No recorder tool found (wl-screenrec or wf-recorder)"
    exit 1
fi

rm -f "$STATE_FILE"
FILE="recording_$(getdate).mp4"
FULL_PATH="$VIDEO_DIR/$FILE"

MONITOR=$(getactivemonitor)
MONITOR_ARG=()
if [ -n "$MONITOR" ] && [ "$RECORDER" = "wl-screenrec" ]; then
    MONITOR_ARG=(-o "$MONITOR")
elif [ -n "$MONITOR" ] && [ "$RECORDER" = "wf-recorder" ]; then
    MONITOR_ARG=(-o "$MONITOR")
fi

case "${1:-}" in
    --fullscreen-all)
        MIC=$(getmicinput)
        echo "$FULL_PATH" > "$STATE_FILE"
        send_notify -i screenshooter -a Recorder -h string:x-canonical-private-synchronous:record "Recording started" "$FILE"
        if [ -n "$MIC" ]; then
            nohup "$RECORDER" "${MONITOR_ARG[@]}" --audio --audio-device "$MIC" -f "$FULL_PATH" >/dev/null 2>&1 &
        else
            nohup "$RECORDER" "${MONITOR_ARG[@]}" --audio -f "$FULL_PATH" >/dev/null 2>&1 &
        fi
        ;;
    --fullscreen-sound)
        SOUND=$(getsystemsound)
        echo "$FULL_PATH" > "$STATE_FILE"
        send_notify -i screenshooter -a Recorder -h string:x-canonical-private-synchronous:record "Recording started" "$FILE"
        if [ -n "$SOUND" ]; then
            nohup "$RECORDER" "${MONITOR_ARG[@]}" --audio --audio-device "$SOUND" -f "$FULL_PATH" >/dev/null 2>&1 &
        else
            nohup "$RECORDER" "${MONITOR_ARG[@]}" --audio -f "$FULL_PATH" >/dev/null 2>&1 &
        fi
        ;;
    --fullscreen)
        echo "$FULL_PATH" > "$STATE_FILE"
        send_notify -i screenshooter -a Recorder -h string:x-canonical-private-synchronous:record "Recording started" "$FILE"
        nohup "$RECORDER" "${MONITOR_ARG[@]}" -f "$FULL_PATH" >/dev/null 2>&1 &
        ;;
    --region|*)
        if command -v slurp >/dev/null 2>&1; then
            region=$(slurp) || {
                send_notify -a Recorder "Recording cancelled"
                rm -f "$STATE_FILE"
                exit 0
            }
            echo "$FULL_PATH" > "$STATE_FILE"
            send_notify -i screenshooter -a Recorder -h string:x-canonical-private-synchronous:record "Recording started" "$FILE"
            if [ "$RECORDER" = "wl-screenrec" ]; then
                nohup "$RECORDER" -g "$region" -f "$FULL_PATH" >/dev/null 2>&1 &
            else
                nohup "$RECORDER" -g "$region" -f "$FULL_PATH" >/dev/null 2>&1 &
            fi
        else
            send_notify -a Recorder "slurp tool missing for region recording"
            exit 1
        fi
        ;;
esac

disown