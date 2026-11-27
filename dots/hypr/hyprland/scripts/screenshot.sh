#!/usr/bin/env bash
set -euo pipefail

DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$DIR"

MODE="${1:-region}"
FILENAME="screenshot_$(date '+%Y-%m-%d_%H-%M-%S').png"
FULL_PATH="$DIR/$FILENAME"

send_notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$@" 2>/dev/null || true
    fi
}

copy_to_clipboard() {
    local file="$1"
    if command -v wl-copy >/dev/null 2>&1 && [ -f "$file" ]; then
        wl-copy -t image/png < "$file" 2>/dev/null || wl-copy "$file" 2>/dev/null || true
    fi
}

SUCCESS=0

if command -v hyprshot >/dev/null 2>&1; then
    hyprshot -m "$MODE" -o "$DIR" -f "$FILENAME" --silent 2>/dev/null || true
elif command -v grim >/dev/null 2>&1; then
    if [ "$MODE" = "region" ] && command -v slurp >/dev/null 2>&1; then
        region=$(slurp) || {
            send_notify -i camera-photo -a "Screenshot" -h string:x-canonical-private-synchronous:screenshot "Screenshot Cancelled" ""
            exit 0
        }
        grim -g "$region" "$FULL_PATH" 2>/dev/null || true
    else
        grim "$FULL_PATH" 2>/dev/null || true
    fi
fi

for _ in $(seq 1 10); do
    if [ -f "$FULL_PATH" ] && [ -s "$FULL_PATH" ]; then
        SUCCESS=1
        break
    fi
    sleep 0.1
done

if [ "$SUCCESS" -eq 1 ] && [ -f "$FULL_PATH" ]; then
    copy_to_clipboard "$FULL_PATH"
    send_notify \
        -i "$FULL_PATH" \
        -a "Screenshot" \
        -h string:x-canonical-private-synchronous:screenshot \
        "Screenshot Saved" \
        "$FILENAME"
else
    send_notify \
        -i camera-photo \
        -a "Screenshot" \
        -h string:x-canonical-private-synchronous:screenshot \
        "Screenshot Cancelled" ""
fi