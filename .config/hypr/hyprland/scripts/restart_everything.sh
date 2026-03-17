#!/bin/bash

# Kill & restart Ironbar
pkill ironbar
sleep 0.5
ironbar &

# Kill & restart Mako
pkill fnott
sleep 0.5
fnott &

# Restart Bluetooth service
systemctl --user restart bluetooth.service 2>/dev/null || \
sudo systemctl restart bluetooth.service
