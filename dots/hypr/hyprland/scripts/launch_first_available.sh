#!/usr/bin/env bash
set -euo pipefail

for cmd in "$@"; do
    # Extract binary executable name
    read -r binary _ <<< "$cmd"
    if command -v "$binary" >/dev/null 2>&1; then
        nohup bash -c "$cmd" >/dev/null 2>&1 &
        exit 0
    fi
done

exit 1