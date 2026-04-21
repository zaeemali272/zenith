#!/bin/bash

set -e

[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

echo "[*] Installing Secure Mode System (Exact Script Deployment)..."

mkdir -p /usr/local/bin

# ==============================================================================
# SECURE ON (YOUR EXACT VERSION - UNTOUCHED LOGIC)
# ==============================================================================
cat <<'EOF' > /usr/local/bin/secure-on
#!/bin/bash

set -e
[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

echo "[*] Starting system hardening..."

echo "[*] Configuring iwd MAC privacy..."
mkdir -p /etc/iwd
cat <<EOC > /etc/iwd/main.conf
[General]
AddressRandomization=network
AddressRandomizationRange=full
EOC

echo "[*] Applying kernel hardening..."
cat <<EOC > /etc/sysctl.d/99-hardening.conf

net.ipv4.conf.all.rp_filter=2
net.ipv4.conf.default.rp_filter=2

net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1

net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0

net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1

kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2

net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOC

sysctl --system

echo "[*] Configuring DNS-over-TLS..."
mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOC > /etc/systemd/resolved.conf.d/dns.conf
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=1.0.0.1#cloudflare-dns.com
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
EOC

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

echo "[*] Applying firewall rules..."

ufw --force reset
ufw default deny incoming
ufw default deny outgoing
ufw logging medium

ufw allow in on lo
ufw allow out on lo

ufw allow out 53/udp
ufw allow out 53/tcp
ufw allow out 853/tcp
ufw allow out 80/tcp
ufw allow out 443/tcp
ufw allow out 443/udp
ufw allow out 123/udp
ufw allow out 67,68/udp

LAN=("192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12")

for NET in "${LAN[@]}"; do
    ufw allow in from "$NET" to any port 5353 proto udp
    ufw allow out to "$NET" port 5353 proto udp

    ufw allow in from "$NET" to any port 1714:1764 proto tcp
    ufw allow in from "$NET" to any port 1714:1764 proto udp
    ufw allow out to "$NET" port 1714:1764 proto tcp
    ufw allow out to "$NET" port 1714:1764 proto udp
done

ufw allow out to 224.0.0.251 port 5353 proto udp

ufw enable

echo "[+] Hardening complete."
EOF

chmod +x /usr/local/bin/secure-on

# ==============================================================================
# SECURE OFF (YOUR EXACT VERSION)
# ==============================================================================
cat <<'EOF' > /usr/local/bin/secure-off
#!/bin/bash

set -e
[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

echo "[*] Reverting system hardening..."

ufw --force reset
ufw default allow incoming
ufw default allow outgoing
ufw logging off
ufw disable

rm -f /etc/sysctl.d/99-hardening.conf
sysctl --system

rm -f /etc/systemd/resolved.conf.d/*.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

rm -f /etc/iwd/main.conf
systemctl restart iwd

echo "[+] Hardening fully disabled."
EOF

chmod +x /usr/local/bin/secure-off

# ==============================================================================
# TOGGLE COMMAND
# ==============================================================================
cat <<'EOF' > /usr/local/bin/secure-mode
#!/bin/bash

case "$1" in
    on)
        secure-on
        ;;
    off)
        secure-off
        ;;
    status)
        ufw status verbose
        echo ""
        sysctl net.ipv4.conf.all.rp_filter
        ;;
    *)
        echo "Usage: secure-mode {on|off|status}"
        ;;
esac
EOF

chmod +x /usr/local/bin/secure-mode

echo "[+] Installation complete."
echo "Commands:"
echo "  secure-mode on"
echo "  secure-mode off"
echo "  secure-mode status"
