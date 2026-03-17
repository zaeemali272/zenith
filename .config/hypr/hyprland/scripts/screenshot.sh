#!/usr/bin/env bash
set -e

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

MODE="$1"

hyprshot -m "$MODE" -o "$DIR"

notify-send \
  -i camera-photo \
  -a Screenshot \
  -h string:x-canonical-private-synchronous:screenshot \
  "Screenshot saved" \
  "Click to open Screenshots folder"

