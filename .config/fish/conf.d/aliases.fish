# ~/.config/fish/conf.d/aliases.fish

alias pamcan pacman
alias ls 'eza --icons'
alias clear "printf '\033[2J\033[3J\033[1;1H'"

alias yt 'yt-dlp'
alias gl 'gallery-dl'

# Lenovo Conservation Mode
alias con 'sudo sh -c "echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"'
alias coff 'sudo sh -c "echo 0 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"'
alias checkc 'cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode'

# Power governor check
alias checkp 'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'

# System controls
alias bon 'sudo systemctl restart bluetooth.service'
alias bac 'bluetoothctl connect 41:42:E8:67:6B:66'
alias mon 'sudo systemctl enable mysqld'
alias moff 'sudo systemctl disable mysqld'

# Quick config edit
alias execs 'nano ~/.config/hypr/hyprland/execs.conf'
alias keybinds 'nano ~/.config/hypr/hyprland/keybinds.conf'
alias general 'nano ~/.config/hypr/hyprland/general.conf'
alias env 'nano ~/.config/hypr/hyprland/env.conf'
alias colors 'nano ~/.config/hypr/hyprland/colors.conf'
alias rules 'nano ~/.config/hypr/hyprland/rules.conf'

alias conf 'nano ~/.config/fish/config.fish'
alias net 'sudo ~/.local/bin/switch_wifi.sh $argv'
