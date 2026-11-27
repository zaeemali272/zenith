#!/usr/bin/env bash
# Select a screen region, OCR it, copy the text to the clipboard.
set -uo pipefail

for tool in grim slurp tesseract wl-copy; do
    command -v "$tool" >/dev/null 2>&1 || {
        notify-send -a "OCR" -i dialog-error "OCR unavailable" "$tool is not installed" 2>/dev/null
        exit 1
    }
done

region="$(slurp)" || exit 0 # selection cancelled

tmp="$(mktemp -t zenith-ocr-XXXXXX.png)"
trap 'rm -f "$tmp"' EXIT

grim -g "$region" "$tmp" || exit 1
text="$(tesseract "$tmp" - 2>/dev/null)"

if [ -z "${text//[[:space:]]/}" ]; then
    notify-send -a "OCR" -i edit-find "No text found" 2>/dev/null
    exit 0
fi

printf '%s' "$text" | wl-copy
notify-send -a "OCR" -i edit-copy "Text copied" "$(printf '%s' "$text" | head -c 120)" 2>/dev/null
