#!/bin/bash

# 1. Create necessary directories
mkdir -p ~/.config/pipewire/pipewire.conf.d
mkdir -p ~/.config/wireplumber/wireplumber.conf.d

# 2. Configure PipeWire Quantum and Sample Rates
# This prevents the CPU from waking up too often and ensures no weird resampling
cat <<EOF > ~/.config/pipewire/pipewire.conf.d/custom-quantum.conf
context.properties = {
    default.clock.rate = 48000
    default.clock.allowed-rates = [ 44100 48000 88200 96000 ]
    default.clock.quantum = 1024
    default.clock.min-quantum = 512
    default.clock.max-quantum = 2048
}
EOF

# 3. Disable Bluetooth Modem Polling (The 2% CPU Fix)
# This stops WirePlumber from looping on "modem not available" errors
cat <<EOF > ~/.config/wireplumber/wireplumber.conf.d/10-disable-modem.conf
wireplumber.settings = {
    bluetooth.autoswitch-to-headset-profile = false
}

monitor.bluez.properties = {
    bluez5.roles = [ a2dp_sink a2dp_source ]
    bluez5.hfphsp-backend = "none"
}
EOF

# 4. Cleanup and Restart
echo "Cleaning WirePlumber state and restarting services..."
rm -rf ~/.local/state/wireplumber/*
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "Done! Check your CPU usage in 'glances' or 'top' now."
