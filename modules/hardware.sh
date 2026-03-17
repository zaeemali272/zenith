#!/usr/bin/env bash

declare -a HARDWARE_PKGS=()

detect_hardware() {
    log_step "🔍 Detecting hardware..."
    
    # 1. GPU Detection
    if lspci | grep -qi "nvidia"; then
        log "NVIDIA GPU detected. Adding proprietary drivers."
        HARDWARE_PKGS+=("nvidia-dkms" "nvidia-utils" "nvidia-settings" "libva-nvidia-driver" "lib32-nvidia-utils")
    elif lspci | grep -qi "amd"; then
        log "AMD GPU detected. Adding open-source drivers."
        HARDWARE_PKGS+=("xf86-video-amdgpu" "mesa" "libva-mesa-driver" "lib32-mesa")
    elif lspci | grep -qi "intel"; then
        log "Intel GPU detected."
        HARDWARE_PKGS+=("vulkan-intel" "intel-media-driver" "libva-intel-driver" "lib32-vulkan-intel")
    fi

    # 2. Virtualization Check
    if systemd-detect-virt -q; then
        VIRT=$(systemd-detect-virt)
        log "Virtualization detected: $VIRT"
        case "$VIRT" in
            oracle) HARDWARE_PKGS+=("virtualbox-guest-utils") ;;
            vmware) HARDWARE_PKGS+=("open-vm-tools" "xf86-video-vmware") ;;
            kvm|qemu) HARDWARE_PKGS+=("qemu-guest-agent") ;;
        esac
    fi

    # 3. Laptop & Power Management
    if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /proc/acpi/button/lid ]]; then
        log "Laptop detected. Adding power management tools."
        HARDWARE_PKGS+=("brightnessctl" "tlp" "acpi")
    fi

    # 4. Bluetooth Support
    if lspci | grep -qi "bluetooth" || lsusb | grep -qi "bluetooth"; then
        log "Bluetooth hardware found."
        HARDWARE_PKGS+=("bluez" "bluez-utils")
    fi

    # 5. Audio Support
    HARDWARE_PKGS+=("pipewire" "pipewire-alsa" "pipewire-pulse" "pipewire-jack" "wireplumber")
}