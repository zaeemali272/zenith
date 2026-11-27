{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    loginShellInit = ''
      if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY"
        if string match -q "*/tty1" (tty)
          exec start-hyprland
        end
      end
    '';
  };
  
  environment.variables.TERMINAL = "kitty";
  programs.dconf.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Add any common libraries binaries might look for
      stdenv.cc.cc.lib
      zlib
      glib
    ];
  };
}