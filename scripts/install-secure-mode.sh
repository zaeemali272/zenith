#!/bin/bash
set -e
if ! command -v ufw &>/dev/null; then
    sudo pacman -S --needed --noconfirm ufw
fi
echo "[*] Secure Mode System installed."
USER_NAME=$(logname 2>/dev/null || echo $USER)
echo "$USER_NAME ALL=(ALL) NOPASSWD: /usr/local/bin/secure-mode" | sudo tee /etc/sudoers.d/secure-mode >/dev/null
sudo chmod 440 /etc/sudoers.d/secure-mode
