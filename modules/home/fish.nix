{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      neofetch = "zenfetch";
      ls = "eza --icons";
      ll = "eza -la --icons --git";
      tree = "eza --tree --icons";
      cat = "bat --paging=never";
    };

    plugins = with pkgs.fishPlugins; [
      { name = "fzf-fish"; src = fzf-fish.src; }
      { name = "done"; src = done.src; }
      { name = "bass"; src = bass.src; }
      { name = "autopair"; src = autopair.src; }
      { name = "puffer"; src = puffer.src; }
      { name = "sponge"; src = sponge.src; }
    ];

    interactiveShellInit = ''
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
      if status is-interactive
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
    '';

    functions = {
      # gituser <account>  - switch which GitHub account git uses from now on.
      #   gituser zaeem     -> zaeemali272 (personal)
      #   gituser zenova    -> ZENOVA-WEB
      # Sets the commit identity in the current repo (if in one) and makes
      # gh hand git that account's token for pushes and pulls.
      gituser = ''
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
      '';
    };
  };
}
