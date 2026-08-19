#!/usr/bin/env bash
# Move from the iwd + systemd-networkd + AdGuard stack to NetworkManager.
#
# install-network-stack.sh set up iwd for wifi, systemd-networkd for addressing
# and systemd-resolved pointed at a local AdGuard Home on 127.0.0.1:5353. That
# works, but it is a lot of moving parts, and if AdGuard is ever removed or
# stops, DNS resolves nothing while the network itself looks perfectly fine.
#
# This migrates to NetworkManager and undoes each piece in an order that never
# leaves the machine without a way to get online.
#
#   --dry-run   print what would happen, change nothing
#   --keep-dns  leave the AdGuard DNS configuration alone
set -uo pipefail

DRY_RUN=0; KEEP_DNS=0
for a in "$@"; do
    case "$a" in
        --dry-run)  DRY_RUN=1 ;;
        --keep-dns) KEEP_DNS=1 ;;
        -h|--help)  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    esac
done

say()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[1;32mok\033[0m    %s\n' "$*"; }
warn() { printf '  \033[1;33m!!\033[0m    %s\n' "$*"; }
die()  { printf '  \033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then printf '  would: %s\n' "$*"; else "$@"; fi; }

[[ $EUID -eq 0 ]] && die "Run as your normal user, not root."
command -v pacman >/dev/null 2>&1 || die "This script is for Arch-based systems."

BACKUP="$HOME/.zenith-network-backup-$(date +%Y%m%d%H%M%S)"

echo "== what is running now =="
for svc in iwd systemd-networkd systemd-resolved NetworkManager adguardhome; do
    printf '  %-18s %s\n' "$svc" "$(systemctl is-active "$svc" 2>/dev/null || echo inactive)"
done

echo
echo "== saved wifi networks =="
# iwd keeps one file per network in /var/lib/iwd. Without importing these the
# machine comes back up unable to join the network it is standing next to.
SSIDS=()
if sudo test -d /var/lib/iwd; then
    while IFS= read -r f; do
        [[ -n "$f" ]] && SSIDS+=("$(basename "$f" | sed 's/\.[^.]*$//')")
    done < <(sudo find /var/lib/iwd -maxdepth 1 -type f \( -name '*.psk' -o -name '*.open' -o -name '*.8021x' \) 2>/dev/null)
fi
if [[ ${#SSIDS[@]} -gt 0 ]]; then
    say "found ${#SSIDS[@]}: ${SSIDS[*]}"
    say "their passphrases will be copied into NetworkManager below"
else
    say "none found -- you will need to reconnect by hand afterwards"
fi

echo
echo "== 1. install NetworkManager first =="
# Installed before anything is torn down, so a failure here leaves the working
# stack untouched.
run sudo pacman -S --needed --noconfirm networkmanager || die "could not install networkmanager"
ok "networkmanager present"

echo
echo "== 2. back up the current configuration =="
run mkdir -p "$BACKUP"
for f in /etc/iwd/main.conf /etc/systemd/resolved.conf \
         /etc/systemd/network/20-wired.network /etc/systemd/network/25-wireless.network; do
    [[ -e "$f" ]] && run sudo cp -a "$f" "$BACKUP/" 2>/dev/null
done
[[ $DRY_RUN -eq 0 ]] && sudo test -d /var/lib/iwd && run sudo cp -a /var/lib/iwd "$BACKUP/iwd-state"
ok "backup at $BACKUP"

echo
echo "== 3. import wifi credentials into NetworkManager =="
if [[ ${#SSIDS[@]} -gt 0 && $DRY_RUN -eq 0 ]]; then
    for ssid in "${SSIDS[@]}"; do
        psk="$(sudo grep -hs '^PreSharedKey=' "/var/lib/iwd/$ssid".* 2>/dev/null | head -1 | cut -d= -f2-)"
        pass="$(sudo grep -hs '^Passphrase=' "/var/lib/iwd/$ssid".* 2>/dev/null | head -1 | cut -d= -f2-)"
        secret="${pass:-$psk}"
        if [[ -n "$secret" ]]; then
            sudo nmcli connection add type wifi con-name "$ssid" ssid "$ssid" \
                wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$secret" >/dev/null 2>&1 \
                && ok "imported $ssid" || warn "could not import $ssid"
        else
            warn "$ssid has no stored passphrase (open network, or 802.1x) -- reconnect manually"
        fi
    done
else
    say "(skipped in dry-run)"
fi

echo
echo "== 4. stop the old stack =="
for svc in iwd systemd-networkd systemd-networkd.socket; do
    systemctl list-unit-files 2>/dev/null | grep -q "^${svc}" && run sudo systemctl disable --now "$svc"
done
ok "iwd and systemd-networkd disabled"

echo
echo "== 5. DNS =="
if [[ $KEEP_DNS -eq 1 ]]; then
    say "left alone (--keep-dns)"
else
    # resolved.conf points at AdGuard on 127.0.0.1:5353 with no fallback. If
    # AdGuard is not running, nothing resolves -- and NetworkManager cannot fix
    # that, because the setting overrides whatever DHCP hands over.
    if [[ -f /etc/systemd/resolved.conf ]] && grep -q "127.0.0.1:5353" /etc/systemd/resolved.conf 2>/dev/null; then
        say "resolved.conf points DNS at AdGuard (127.0.0.1:5353) with no fallback"
        if systemctl is-active --quiet adguardhome 2>/dev/null; then
            say "AdGuard is running, so this still works. Keeping it."
            say "To hand DNS back to your network later: sudo rm /etc/systemd/resolved.conf"
        else
            warn "AdGuard is NOT running -- with this file in place nothing resolves"
            run sudo mv /etc/systemd/resolved.conf "$BACKUP/resolved.conf"
            ok "moved aside; DNS now follows the network"
        fi
    else
        ok "no AdGuard DNS override to undo"
    fi
    # NetworkManager and resolved cooperate through the stub resolver.
    [[ -L /etc/resolv.conf ]] || run sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    run sudo systemctl enable --now systemd-resolved
fi

echo
echo "== 6. hand the interfaces to NetworkManager =="
for f in /etc/systemd/network/20-wired.network /etc/systemd/network/25-wireless.network; do
    [[ -e "$f" ]] && run sudo mv "$f" "$BACKUP/"
done
run sudo systemctl enable --now NetworkManager
ok "NetworkManager enabled"

echo
echo "== 7. check =="
if [[ $DRY_RUN -eq 0 ]]; then
    sleep 3
    systemctl is-active --quiet NetworkManager && ok "NetworkManager is active" \
        || warn "NetworkManager did not start -- see: journalctl -u NetworkManager"
    if ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; then
        ok "network is up"
        ping -c1 -W3 archlinux.org >/dev/null 2>&1 && ok "DNS resolves" \
            || warn "no DNS. Try: sudo rm /etc/systemd/resolved.conf && sudo systemctl restart systemd-resolved"
    else
        warn "no connectivity yet -- connect with: nmcli device wifi list && nmcli device wifi connect <SSID>"
    fi
fi

echo
say "Backup of everything changed: $BACKUP"
say "To go back:  sudo systemctl disable --now NetworkManager && sudo systemctl enable --now iwd systemd-networkd"
say "Remove iwd once you are happy:  sudo pacman -Rns iwd"
