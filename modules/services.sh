#!/usr/bin/env bash

setup_system_services() {
    log_step "🔌 Configuring system services..."
    
    # Handle Network Manager vs iwd
    # Only switch to iwd if NetworkManager is running and we decide to switch, or if user asks?
    # For now, let's just make it robust: Don't disable NM unless we are sure.
    # Actually, the user wants "Perfect" & "Automatic".
    # Zenith seems to prefer iwd. We'll proceed but log clearly.
    
    if systemctl is-active --quiet NetworkManager.service; then
        log_warn "Disabling NetworkManager to use iwd (Zenith default)..."
        sudo systemctl disable --now NetworkManager.service 2>/dev/null || true
    fi

    # iwd setup
    sudo mkdir -p /etc/iwd
    if [[ -f /etc/iwd/main.conf ]]; then
         sudo cp /etc/iwd/main.conf /etc/iwd/main.conf$BACKUP_SUFFIX
    fi
    
    echo -e "[General]\nEnableNetworkConfiguration=true" | sudo tee /etc/iwd/main.conf >/dev/null
    sudo systemctl enable --now iwd.service bluez.service || log_error "Failed to enable iwd/bluez."
    
    # Bluetooth Autofix
    if [[ -f "$DOTS_DIR/systemd/system/bluetooth-autofix.service" ]]; then
        sudo cp "$DOTS_DIR/systemd/system/bluetooth-autofix.service" /etc/systemd/system/
        sudo systemctl daemon-reload && sudo systemctl enable --now bluetooth-autofix.service || log_warn "Failed to enable bluetooth-autofix."
    fi
    log_success "System services configured."
}

setup_autologin() {
    log_step "🔑 Setting up autologin for user '$USER' on tty1"
    local service_dir="/etc/systemd/system/getty@tty1.service.d"
    sudo mkdir -p "$service_dir"
    echo -e "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin $USER %I \$TERM >/dev/null 2>&1" | sudo tee "$service_dir/override.conf" >/dev/null
    sudo systemctl daemon-reexec
    log_success "Autologin set."
}

setup_cpu_governor() {
    if has_run "setup_cpu_governor"; then return; fi
    log_step "⚡ Setting up advanced CPU governor auto-switch..."

    # Governor script
    cat <<'EOF' | sudo tee /usr/local/bin/set-governor.sh >/dev/null
#!/bin/sh
AC_ON=0
for AC in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
    [ -f "$AC" ] && [ "$(cat $AC)" = "1" ] && AC_ON=1 && break
done
AVAILABLE=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
PERF=$(echo "$AVAILABLE" | grep -qw performance && echo "performance" || echo "$AVAILABLE" | awk '{print $1}')
SAVE=$(echo "$AVAILABLE" | grep -qw powersave && echo "powersave" || echo "$PERF")
for c in /sys/devices/system/cpu/cpu[0-9]*; do
    [ -f "$c/cpufreq/scaling_governor" ] && ( [ "$AC_ON" = "1" ] && echo "$PERF" || echo "$SAVE" ) > "$c/cpufreq/scaling_governor"
done
EOF
    sudo chmod +x /usr/local/bin/set-governor.sh

    # Udev & Service
    echo 'ACTION=="change", SUBSYSTEM=="power_supply", RUN+="/usr/local/bin/set-governor.sh"' | sudo tee /etc/udev/rules.d/99-governor.rules >/dev/null
    cat <<'EOF' | sudo tee /etc/systemd/system/set-governor.service >/dev/null
[Unit]
Description=Set CPU governor based on AC/Battery
[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-governor.sh
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload && sudo systemctl enable --now set-governor.service
    mark_done "setup_cpu_governor"
    log_success "CPU governor service enabled."
}

optimize_bootloader() {
    log_step "⚡ Optimizing bootloader..."
    
    # Check for Systemd-boot
    if [[ -d /boot/loader/entries ]]; then
        # Instant boot
        [[ -f /boot/loader/loader.conf ]] && sudo sed -i 's/^timeout.*/timeout 0/' /boot/loader/loader.conf || echo "timeout 0" | sudo tee -a /boot/loader/loader.conf >/dev/null

        # Quiet flags
        local entry=$(find /boot/loader/entries/ -type f -name "*.conf" ! -iname "*fallback*" | head -n 1)
        if [[ -n "$entry" ]]; then
            sudo sed -i -E 's/\b(quiet|splash|loglevel=[^ ]*|rd\.udev\.log_priority=[^ ]*|rd\.systemd\.show_status=[^ ]*)\b//g' "$entry"
            sudo sed -i -E 's|^(options\s+.*)|\1 quiet splash loglevel=3 rd.systemd.show_status=false vt.global_cursor_default=0|' "$entry"
        fi
        log_success "Systemd-boot optimized."
    elif [[ -f /boot/grub/grub.cfg ]]; then
        log_step "GRUB detected. Adding quiet flags to /etc/default/grub..."
        # Backup grub config
        sudo cp /etc/default/grub /etc/default/grub$BACKUP_SUFFIX
        
        # Modify GRUB_CMDLINE_LINUX_DEFAULT
        # Ensure quiet and splash are there, add others if missing
        local flags="quiet splash loglevel=3 rd.systemd.show_status=false vt.global_cursor_default=0"
        
        # Simple replacement for now - robust regex handling for GRUB lines is complex, 
        # so we'll just ensure the line exists with our desired flags if it's not already perfect.
        # A safer way is to append to the variable.
        
        if ! grep -q "vt.global_cursor_default=0" /etc/default/grub; then
             sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$flags /" /etc/default/grub
             # Regenerate grub config? Usually 'grub-mkconfig -o ...' but path varies (EFI/BIOS).
             # To be safe, we just update the file and let the user know, or try standard paths.
             log_warn "Updated /etc/default/grub. Please run 'sudo grub-mkconfig -o /boot/grub/grub.cfg' to apply."
        else
             log_success "GRUB already seems optimized."
        fi
    else
        log_warn "No supported bootloader config found (systemd-boot or GRUB). Skipping optimization."
    fi
}
