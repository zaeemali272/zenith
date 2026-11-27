if status is-interactive
    set -g fish_greeting

    # Dynamic Zenith theme (FZF & syntax colors)
    if test -f ~/.cache/zenith/zenith-fzf.fish
        source ~/.cache/zenith/zenith-fzf.fish
    end

    # Modern tool hooks
    if type -q zoxide
        zoxide init fish | source
    end

    if type -q direnv
        direnv hook fish | source
    end

    # Run Zenith Fetch on initial interactive launch
    if test -z "$NVIM" -a -z "$YAZI_LEVEL" -a -z "$RANGER_LEVEL" -a "$TERM" != "dumb"
        set -l current_tty (tty 2>/dev/null)
        if test -n "$current_tty" -a "$current_tty" != "not a tty"
            if test "$ZENFETCH_TTY" != "$current_tty"
                set -gx ZENFETCH_TTY "$current_tty"
                set -g ZENFETCH_SHOWN 1
                if type -q zenfetch
                    zenfetch
                else if test -x ~/.local/bin/zenfetch
                    ~/.local/bin/zenfetch
                end
            end
        else if not set -q ZENFETCH_SHOWN
            set -g ZENFETCH_SHOWN 1
            if type -q zenfetch
                zenfetch
            else if test -x ~/.local/bin/zenfetch
                ~/.local/bin/zenfetch
            end
        end
    end
end

# Shell aliases matching Zenith NixOS
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias tree="eza --tree --icons"
alias cat="bat --paging=never"
alias neofetch="zenfetch"

# Enable Starship prompt
if type -q starship
    starship init fish | source
end

# Auto-start Hyprland on TTY1 if not already running
if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a (tty) = "/dev/tty1"
    exec start-hyprland >/dev/null 2>&1
end

# Standard Zenith Theme & Cursor
set -Ux GTK_THEME Orchis-Dark
set -Ux GTK_ICON_THEME Reversal-dark
set -Ux XCURSOR_THEME Bibata-Modern-Classic
set -Ux XCURSOR_SIZE 24
set -Ux QT_QPA_PLATFORMTHEME qt5ct
set -Ux QT_STYLE_OVERRIDE kvantum-dark

# User PATH
set -U fish_user_paths $HOME/.local/bin $fish_user_paths

# Switch active GitHub account on the fly
function gituser
    set -l login; set -l name; set -l email
    switch "$argv[1]"
        case zaeem zaeemali272
            set login zaeemali272; set name zaeem; set email zaeemali272@gmail.com
        case zenova zenovadevs ZENOVA-WEB
            set login ZENOVA-WEB; set name zenovadevs; set email zenovadevs@gmail.com
        case ayahlink ayahlinkacademy
            set login ayahlink; set name ayahlink; set email ayahlinkacademy@gmail.com
        case '*'
            echo "usage: gituser zaeem | zenova | ayahlink"; return 1
    end
    gh auth switch -h github.com -u $login; or return 1
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        git config user.name $name
        git config user.email $email
        echo "this repo now commits as $name <$email>"
    end
    echo "git now pushes/pulls as $login"
end
