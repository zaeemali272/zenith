#! /bin/bash

if [[ "$(playerctl -p spotify status)" = "Playing"  ]]; then
    hyprlock --config ~/.config/hyprlock/music.conf --grace 300

else :
    hyprlock --config ~/.config/hyprlock/music.conf --grace 300
fi 

