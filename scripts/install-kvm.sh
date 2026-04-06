#!/usr/bin/env bash

# ==============================================================================
# ELITE-TIER KVM/QEMU PROVISIONER (Arch + Hyprland + systemd-boot)
# Version: 2.1 (Fixed: Removed deprecated bridge-utils)
# ==============================================================================

set -euo pipefail

LOGFILE="$HOME/kvm_install.log"

log() {
    local timestamp
    timestamp=$(date '+%F %T')
    if [[ -t 1 ]]; then
        echo -e "\e[1;34m[$timestamp]\e[0m $*" | tee -a "$LOGFILE"
    else
        echo "[$timestamp] $*" >> "$LOGFILE"
    fi
}

CURRENT_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$CURRENT_USER" | cut -d: -f6)

if [[ $EUID -ne 0 ]]; then
    echo "Critical: This script must be run with sudo."
    exit 1
fi

log "Initializing Titan-Grade Environment for $CURRENT_USER..."

# 1. Hardware Validation
if [[ ! -e /dev/kvm ]]; then
    log "ERROR: /dev/kvm not found! Virtualization is DISABLED in BIOS."
    exit 1
fi

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
case "$CPU_VENDOR" in
    GenuineIntel) IOMMU_FLAGS="intel_iommu=on iommu=pt" ;;
    AuthenticAMD) IOMMU_FLAGS="amd_iommu=on iommu=pt" ;;
    *) IOMMU_FLAGS="" ;;
esac

# 2. Bootloader Patching (Improved Logic)
if bootctl is-installed &>/dev/null; then
    ENTRY_NAME=$(bootctl list 2>/dev/null | awk '/\*/ {print $2}' | head -n1)
    if [[ -z "$ENTRY_NAME" ]]; then
        ENTRY_PATH=$(find /boot/loader/entries -name "*.conf" | head -n1 || true)
    else
        ENTRY_PATH="/boot/loader/entries/$(basename "$ENTRY_NAME").conf"
    fi

    if [[ -n "$ENTRY_PATH" && -f "$ENTRY_PATH" && -n "$IOMMU_FLAGS" ]]; then
        if ! grep -q "$IOMMU_FLAGS" "$ENTRY_PATH"; then
            sed -i "/^options / s/$/ $IOMMU_FLAGS/" "$ENTRY_PATH"
            log "Success: Patched systemd-boot entry ($(basename "$ENTRY_PATH"))"
        else
            log "Notice: IOMMU flags already present in $(basename "$ENTRY_PATH")."
        fi
    fi
fi

# 3. Package Installation (Fixed: Removed bridge-utils)
log "Swapping iptables for nftables stack..."
pacman -Rdd --noconfirm iptables 2>/dev/null || true

log "Installing Virtualization Stack..."
# Removed bridge-utils as it's deprecated/removed in Arch
pacman -Syu --needed --noconfirm \
    qemu-full libvirt virt-manager dnsmasq edk2-ovmf \
    swtpm guestfs-tools virglrenderer wget \
    iptables-nft nftables

# 4. Services & Permissions
log "Enabling Libvirt services..."
systemctl daemon-reexec 
systemctl enable --now libvirtd.socket virtlogd.socket

for grp in libvirt kvm render video; do
    groupadd -f "$grp"
    usermod -aG "$grp" "$CURRENT_USER"
done

# 5. QEMU Config (Performance)
QEMU_CONF="/etc/libvirt/qemu.conf"
log "Optimizing $QEMU_CONF..."
sed -i "s|^#user = .*|user = \"$CURRENT_USER\"|" "$QEMU_CONF"
sed -i "s|^#group = .*|group = \"libvirt\"|" "$QEMU_CONF"

if ! grep -q "memory_backing_dir" "$QEMU_CONF"; then
    echo 'memory_backing_dir = "/dev/shm"' >> "$QEMU_CONF"
fi
systemctl restart libvirtd

# 6. NAT Networking
log "Provisioning virbr0 bridge..."
cat <<EOF > /tmp/default-net.xml
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp><range start='192.168.122.2' end='192.168.122.254'/></dhcp>
  </ip>
</network>
EOF

if ! virsh net-info default &>/dev/null; then
    virsh net-define /tmp/default-net.xml
fi
virsh net-start default 2>/dev/null || true
virsh net-autostart default

# 7. Polkit & GUI
log "Installing Polkit rules..."
cat <<EOF > /etc/polkit-1/rules.d/80-libvirt.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF

mkdir -p "$USER_HOME/.config/virt-manager"
cat <<EOF > "$USER_HOME/.config/virt-manager/virt-manager.conf"
[main]
show_xml_editor = 1
EOF
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/virt-manager"

log "Titan-Grade provisioning complete."
echo "--------------------------------------------------"
echo "   REBOOT REQUIRED TO APPLY CHANGES"
echo "--------------------------------------------------"
