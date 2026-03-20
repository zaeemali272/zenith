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
echo "[*] Installing required packages..."
sudo pacman -Sy --noconfirm iwd systemd

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
sudo tee /etc/systemd/network/20-wired.network > /dev/null <<EOF
[Match]
Name=en*

[Network]
DHCP=yes
IPv6AcceptRA=yes
EOF

# Wireless
sudo tee /etc/systemd/network/25-wireless.network > /dev/null <<EOF
[Match]
Name=wl*

[Network]
DHCP=yes
IPv6AcceptRA=yes
EOF

# -------------------------------
# 5. Configure systemd-resolved (Cloudflare + DoT)
# -------------------------------
echo "[*] Configuring systemd-resolved..."
sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=9.9.9.9 8.8.8.8
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
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

for svc in iwd systemd-networkd systemd-resolved systemd-timesyncd; do
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
echo "Logs:"
echo "  journalctl -u iwd -u systemd-networkd -u systemd-resolved"
echo ""
echo "[*] Ready for future VPN or ZeroTier setup!"