#!/usr/bin/env bash

# This script launches the post-boot installer in a Quickshell window.
export JSON_OUTPUT=true

# Detect DOTS_DIR dynamically - this script is in .config/hypr/
# We assume it's running from its installed location in ~/.config/hypr/
# But to be safe, we can look for the zenith folder or use a common location.
# During installation, DOTS_DIR is usually where the installer was run from.
# We'll try to find where the scripts/post_boot_install.sh is.

# Possible locations for DOTS_DIR
SEARCH_PATHS=(
    "$HOME/Downloads/zenith"
    "$HOME/Documents/Linux/Dots/zenith"
    "$(cd "$(dirname "$0")/../.." && pwd)"
)

export DOTS_DIR=""
for path in "${SEARCH_PATHS[@]}"; do
    if [[ -f "$path/scripts/post_boot_install.sh" ]]; then
        export DOTS_DIR="$path"
        break
    fi
done

if [[ -z "$DOTS_DIR" ]]; then
    echo "Error: Could not find Zenith directory."
    exit 1
fi

# Ensure we're in the right directory for the install script
cd "$DOTS_DIR/scripts" || exit

# Launch the Quickshell window and pipe the output of the post_boot_install.sh script to it.
# The QML file is in .config/zenith-installer/
/usr/bin/qs -p "$HOME/.config/zenith-installer/installer.qml" < <(bash post_boot_install.sh)
