if status is-interactive
    set fish_greeting
end

# Enable Starship prompt
starship init fish | source

if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
    exec start-hyprland >/dev/null 2>&1
end

set -Ux GTK_THEME dynamic-materia-dark
set -Ux QT_QPA_PLATFORMTHEME qt5ct
set -Ux QT_STYLE_OVERRIDE kvantum-dark
set -Ux GTK_ICON_THEME OneUI-dark

set -U fish_user_paths $HOME/.local/bin $fish_user_paths
