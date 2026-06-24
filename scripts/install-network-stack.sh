#!/usr/bin/env bash
set -euo pipefail

echo "[*] Starting ultimate networking + performance setup..."

# -------------------------------
# 0. Sanity check
# -------------------------------
if [[ $EUID -eq 0 ]]; then
  echo "[!] Do NOT run as root. Use a normal user with sudo."
  exit 1
fi

# -------------------------------
# 1. Install required packages
# -------------------------------
echo "[*] Synchronizing package databases..."
sudo pacman -Sy --noconfirm

echo "[*] Installing required system packages..."
sudo pacman -S --noconfirm --needed iwd systemd

echo "[*] Installing required AUR packages..."
if command -v yay > /dev/null; then
  yay -S --noconfirm --needed adguardhome-bin
else
  echo "[!] Error: yay is not installed. Please install yay to use AUR packages."
  exit 1
fi

# -------------------------------
# 1.5. Enable AdGuard Home
# -------------------------------
echo "[*] Enabling AdGuard Home..."
sudo systemctl enable --now adguardhome

# -------------------------------
# 2. Disable conflicting services
# -------------------------------
echo "[*] Disabling conflicting services..."
for svc in NetworkManager wpa_supplicant dhcpcd; do
  if systemctl list-unit-files | grep -q "^${svc}.service"; then
    sudo systemctl disable --now ${svc}.service || true
  fi
done

# -------------------------------
# 3. Configure iwd (Wi-Fi only)
# -------------------------------
echo "[*] Configuring iwd..."
sudo install -d /etc/iwd

if [[ -f /etc/iwd/main.conf ]]; then
  echo "[*] Backing up /etc/iwd/main.conf..."
  sudo cp /etc/iwd/main.conf /etc/iwd/main.conf.backup
fi

sudo tee /etc/iwd/main.conf > /dev/null <<EOF
[General]
EnableNetworkConfiguration=false
AutoConnect=true
EOF

# -------------------------------
# 4. Configure systemd-networkd
# -------------------------------
echo "[*] Configuring systemd-networkd..."
sudo install -d /etc/systemd/network

# Wired
if [[ -f /etc/systemd/network/20-wired.network ]]; then
  echo "[*] Backing up /etc/systemd/network/20-wired.network..."
  sudo cp /etc/systemd/network/20-wired.network /etc/systemd/network/20-wired.network.backup
fi
sudo tee /etc/systemd/network/20-wired.network > /dev/null <<EOF
[Match]
Name=en*

[Network]
DHCP=yes
IPv6AcceptRA=yes
DNS=127.0.0.1
Domains=~
EOF

# Wireless
if [[ -f /etc/systemd/network/25-wireless.network ]]; then
  echo "[*] Backing up /etc/systemd/network/25-wireless.network..."
  sudo cp /etc/systemd/network/25-wireless.network /etc/systemd/network/25-wireless.network.backup
fi
sudo tee /etc/systemd/network/25-wireless.network > /dev/null <<EOF
[Match]
Name=wl*

[Network]
DHCP=yes
IPv6AcceptRA=yes
DNS=127.0.0.1
Domains=~
EOF

# -------------------------------
# 5. Configure systemd-resolved (Local DNS)
# -------------------------------
echo "[*] Configuring systemd-resolved..."
if [[ -f /etc/systemd/resolved.conf ]]; then
  echo "[*] Backing up /etc/systemd/resolved.conf..."
  sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup
fi
sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=127.0.0.1:5353
FallbackDNS=
Domains=~.
EOF

# Fix resolv.conf safely
if [[ -e /etc/resolv.conf && ! -L /etc/resolv.conf ]]; then
  echo "[*] Backing up existing resolv.conf..."
  sudo mv /etc/resolv.conf /etc/resolv.conf.backup
fi
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# -------------------------------
# 6. Apply sysctl network optimizations
# -------------------------------
echo "[*] Applying kernel network optimizations..."
if [[ -f /etc/sysctl.d/99-network-optimization.conf ]]; then
  echo "[*] Backing up /etc/sysctl.d/99-network-optimization.conf..."
  sudo cp /etc/sysctl.d/99-network-optimization.conf /etc/sysctl.d/99-network-optimization.conf.backup
fi
sudo tee /etc/sysctl.d/99-network-optimization.conf > /dev/null <<EOF
# --- Queue and Congestion Control ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# --- Speed & Connectivity ---
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_window_scaling = 1

# --- Memory Buffers ---
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# --- Privacy & Stealth ---
net.ipv4.icmp_echo_ignore_all = 1

# --- Other Tweaks ---
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 2097152
EOF

sudo sysctl --system

# -------------------------------
# 7. Configure udev rules
# -------------------------------
echo "[*] Installing udev rules..."
sudo install -d /etc/udev/rules.d

# Android devices (optional, keep if you use ADB)
sudo tee /etc/udev/rules.d/51-android.rules > /dev/null <<EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
EOF

# Wi-Fi power save off + MTU for VPN stability
sudo tee /etc/udev/rules.d/81-wifi.powersave.rules > /dev/null <<EOF
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/usr/bin/iw dev %k set power_save off", RUN+="/usr/bin/ip link set dev %k mtu 1492"
EOF

# ZeroTier MTU tweak (important for overlay networks)
sudo tee /etc/udev/rules.d/99-zerotier-mtu.rules > /dev/null <<EOF
ACTION=="add", SUBSYSTEM=="net", KERNEL=="zt*", RUN+="/usr/bin/sh -c 'sleep 2; /usr/bin/ip link set dev %k mtu 1280'"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# -------------------------------
# 8. Enable core services
# -------------------------------
echo "[*] Enabling services..."
sudo systemctl enable iwd.service
sudo systemctl enable systemd-networkd.service
sudo systemctl enable systemd-resolved.service
sudo systemctl enable systemd-timesyncd.service

# Restart to ensure everything is active
sudo systemctl restart iwd.service
sudo systemctl restart systemd-networkd.service
sudo systemctl restart systemd-resolved.service
sudo systemctl restart systemd-timesyncd.service

# -------------------------------
# 9. Health check
# -------------------------------
echo "[*] Checking services..."
sleep 2

for svc in iwd systemd-networkd systemd-resolved systemd-timesyncd adguardhome; do
  if systemctl is-active --quiet $svc; then
    echo "[✓] $svc is active"
  else
    echo "[!] $svc is NOT active, check: journalctl -u $svc"
  fi
done

# -------------------------------
# 10. Final instructions
# -------------------------------
echo ""
echo "======================================"
echo " Ultimate Networking Setup Complete "
echo "======================================"
echo ""
echo "Connect to Wi-Fi:"
echo "  iwctl"
echo "  device list"
echo "  station <interface> connect YOUR_SSID"
echo ""
echo "Check network status:"
echo "  networkctl status"
echo "  resolvectl status"
echo ""
echo "Test internet:"
echo "  ping archlinux.org"
echo ""
echo "IMPORTANT: Disable DNS-over-HTTPS (DoH) in your browsers to prevent bypassing AdGuard Home:"
echo "  * Chrome/Brave/Edge: Settings -> Privacy and security -> Security -> Toggle \"Use secure DNS\" to OFF."
echo "  * Firefox: Settings -> General -> Network Settings -> Uncheck \"Enable DNS over HTTPS\"."
echo ""
echo "Logs:"
echo "  journalctl -u iwd -u systemd-networkd -u systemd-resolved"
echo ""
echo "[*] Ready for future VPN or ZeroTier setup!"
