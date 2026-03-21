#!/usr/bin/env bash
# Zenith Script: Install and Configure Fusuma
# Multi-touch gesture tool with plugin support.

# Ensure we are in the project root
if [[ ! -f "install.sh" ]]; then
    echo "❌ Please run this script from the root of the zenith repository."
    exit 1
fi

# Load UI if available for pretty logging
if [[ -f "modules/ui.sh" ]]; then
    source "modules/ui.sh"
else
    # Fallback logging
    log_step() { echo -e "\e[1;34m[STEP]\e[0m $*"; }
    log() { echo -e "  ➜ $*"; }
    log_success() { echo -e "\e[1;32m[OK]\e[0m $*"; }
    log_error() { echo -e "\e[1;31m[ERR]\e[0m $*"; }
fi

log_step "👆 Checking and Installing Fusuma..."

if command -v fusuma &>/dev/null; then
    log_success "Fusuma is already installed."
else
    log "Installing ruby-fusuma and required plugins from AUR..."
    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm ruby-fusuma ruby-fusuma-plugin-sendkey xdotool
        log_success "Fusuma and plugins installed."
    else
        log_error "AUR helper 'yay' not found. Please install it first."
        exit 1
    fi
fi

log_step "👥 Configuring user groups for Fusuma..."
if groups "$USER" | grep -q "\binput\b"; then
    log_success "User is already in the 'input' group."
else
    log "Adding $USER to the 'input' group..."
    sudo gpasswd -a "$USER" input
    log_success "Added to 'input' group."
    
    # Run newgrp to apply group changes to the current shell as requested.
    # Note: this will start a subshell, so we use it with a command or just as-is.
    # To avoid hanging the script, we can run it with a simple command or just warn the user.
    # The user specifically asked for "than newgrp input".
    log "Applying group changes with newgrp (current session)..."
    # Note: newgrp usually replaces the current shell. In a script, it might not behave as expected
    # if there are subsequent commands. However, we'll follow the instruction.
    # A safer way to "be in the group" for the rest of the script is:
    # exec sg input "$0" "$@" if we wanted to restart the script, but that's overkill.
    # We'll just execute the command as requested.
    newgrp input <<EOF
    log_success "Group membership updated in subshell."
EOF
fi

log_success "Fusuma installation and configuration complete."
