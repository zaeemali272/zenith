#!/usr/bin/env bash
# Debugging script: just log the input
echo "Script called with: Wallpaper=$1, Color=$2" > /tmp/zenith_debug.log
# Ensure we don't depend on matugen for debugging
matugen image "$1" --color "$2" --config "$HOME/.config/matugen/config.toml" >> /tmp/zenith_debug.log 2>&1
