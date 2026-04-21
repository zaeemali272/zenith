#!/bin/bash

# Exit on any error
set -e

echo "--- Starting MariaDB & Beekeeper Setup for Zenith ---"

# 1. Install MariaDB and Beekeeper Studio
echo "[1/5] Installing packages..."
sudo pacman -S --needed --noconfirm mariadb
yay -S --needed --noconfirm beekeeper-studio-bin

# 2. Initialize the MariaDB data directory
# This creates the system tables required for the engine to boot
echo "[2/5] Initializing MariaDB data directory..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# 3. Enable and Start the service
echo "[3/5] Starting MariaDB service..."
sudo systemctl enable --now mariadb

# 4. Secure the installation (Manual Interaction Required)
# This removes anonymous users and sets a root password
echo "[4/5] Running security script..."
echo "TIP: Set a root password and remove test databases when prompted."
sudo mariadb-secure-installation

# 5. Verify Status
echo "[5/5] Checking service status..."
systemctl is-active mariadb

echo "--- Setup Complete! ---"
echo "You can now open Beekeeper Studio from your Hyprland runner."
