#!/usr/bin/env bash

setup_system_services() {
    log_step "🔌 Configuring system services..."

    # --- Power Key Handling ---
    # Prevents the system from shutting down instantly if the power button is bumped
    log_info "Disabling systemd-logind power key handling..."
    if grep -q "^#HandlePowerKey=" /etc/systemd/logind.conf; then
        sudo sed -i 's/^#HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
    elif grep -q "^HandlePowerKey=" /etc/systemd/logind.conf; then
        sudo sed -i 's/^HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
    else
        echo "HandlePowerKey=ignore" | sudo tee -a /etc/systemd/logind.conf >/dev/null
    fi

    # Handle Network Manager vs iwd
    if systemctl is-active --quiet NetworkManager.service; then
        log_warn "Disabling NetworkManager to use iwd (Zenith default)..."
        sudo systemctl disable --now NetworkManager.service 2>/dev/null || true
    fi

    # iwd setup
    sudo mkdir -p /etc/iwd
    if [[ -f /etc/iwd/main.conf ]]; then
         sudo cp /etc/iwd/main.conf /etc/iwd/main.conf$BACKUP_SUFFIX
    fi

    echo -e "[General]
EnableNetworkConfiguration=true" | sudo tee /etc/iwd/main.conf >/dev/null

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
    echo -e "[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER %I \$TERM >/dev/null 2>&1" | sudo tee "$service_dir/override.conf" >/dev/null
    sudo systemctl daemon-reexec
    log_success "Autologin set."
}

optimize_bootloader() {
    log_step "⚡ Optimizing bootloader..."

    # Check for Systemd-boot
    if [[ -d /boot/loader/entries ]]; then
        # Instant boot timeout
        [[ -f /boot/loader/loader.conf ]] && sudo sed -i 's/^timeout.*/timeout 0/' /boot/loader/loader.conf || echo "timeout 0" | sudo tee -a /boot/loader/loader.conf >/dev/null

        local entry=$(find /boot/loader/entries/ -type f -name "*.conf" ! -iname "*fallback*" | head -n 1)
        if [[ -n "$entry" ]]; then
            local current_options=""
            # Read the current options line from the boot entry file
            # Use grep to capture the line starting with 'options '
            # Use sed to remove the 'options ' prefix and capture the rest.
            if sudo grep -q "^options " "$entry"; then
                current_options=$(sudo sed -n -E 's/^options //p' "$entry")
            else
                log_warn "No 'options' line found in $entry. Cannot dynamically extract static parameters."
                # If no options line, we can't extract static params. Defaulting to an empty static param string.
            fi

            # --- Detect IOMMU flags ---
            local IOMMU_FLAGS=""
            # Check if KVM is likely installed/enabled by looking for /dev/kvm or virt-manager
            # Using [ ] for broader compatibility, though [[ ]] is generally preferred in bash.
            if [ -e /dev/kvm ] || [ -f /usr/bin/virt-manager ]; then
                local CPU_VENDOR
                CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
                case "$CPU_VENDOR" in
                    GenuineIntel) IOMMU_FLAGS="intel_iommu=on iommu=pt" ;;
                    AuthenticAMD) IOMMU_FLAGS="amd_iommu=on iommu=pt" ;;
                esac
            fi

            # --- Define core desired kernel parameters ---
            # These are parameters managed by this script for system optimization.
            local CORE_PARAMS="quiet splash loglevel=3 rd.systemd.show_status=false vt.global_cursor_default=0"

            # Combine extracted static parameters, core parameters, and detected IOMMU flags
            local ALL_PARAMS="$current_options $CORE_PARAMS"
            if [[ -n "$IOMMU_FLAGS" ]]; then
                ALL_PARAMS="$ALL_PARAMS $IOMMU_FLAGS"
            fi

            # Ensure no duplicate parameters and clean up spacing using awk
            # The awk script:
            # 1. Cleans multiple spaces into single spaces and trims leading/trailing spaces.
            # 2. Splits the line into parameters based on spaces.
            # 3. Uses an associative array 'seen' to track unique parameter keys.
            # 4. Reconstructs the string with unique parameters and single spacing.
            local unique_params
            unique_params=$(echo "$ALL_PARAMS" | awk '
                # Clean up existing whitespace and trim leading/trailing spaces
                {
                    gsub(/[[:space:]]+/, " ", $0);
                    gsub(/^ | $/, "", $0);

                    # Split into parameters and process for uniqueness
                    split($0, params, " ");
                    for (i = 1; i <= length(params); i++) {
                        param_with_value = params[i];
                        if (param_with_value == "") next; # Skip empty parameters

                        # Extract the key part of the parameter (e.g., "root" from "root=...")
                        split(param_with_value, parts, "=");
                        param_key = parts[1];

                        # Store the parameter if its key has not been seen yet
                        if (!seen[param_key]) {
                            seen[param_key] = param_with_value;
                        }
                    }
                    # Reconstruct the string from unique parameters
                    first = 1;
                    for (p_key in seen) {
                        if (!first) printf " ";
                        printf "%s", seen[p_key];
                        first = 0;
                    }
                }
            ')

            # Construct the final options line
            local final_options_line="options $unique_params"

            # Update the file by replacing the entire 'options' line.
            # This ensures a clean slate with only the desired, unique parameters.
            sudo sed -i -E "s|^options .*|$final_options_line|" "$entry"

            log_success "Systemd-boot optimized with consolidated parameters."
        else
            log_warn "No systemd-boot entry file found to optimize."
        fi
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
