#!/usr/bin/env bash

# This script launches the post-boot installer in a Quickshell window.
export JSON_OUTPUT=true

# Ensure we're in the right directory
cd "$HOME/Documents/Linux/Dots/zenith/scripts" || exit

# Launch the Quickshell window and pipe the output of the post_boot_install.sh script to it.
/usr/bin/qs -p "$HOME/.config/zenith-installer/installer.qml" < <(bash post_boot_install.sh)
