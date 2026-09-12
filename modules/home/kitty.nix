{ pkgs, ... }: {
  programs.kitty = {
    enable = true;
    settings = {
      # Multi-line pastes count as "control codes" and trigger a confirm
      # dialog on every paste; only warn on large ones and keep URLs quoted.
      paste_actions = "quote-urls-at-prompt,confirm-if-large";
    };
  };

  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=kitty
  '';

  xdg.dataFile."xfce4/helpers/kitty.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Icon=kitty
    Name=Kitty Terminal Emulator
    Type=X-XFCE-Helper
    X-XFCE-Category=TerminalEmulator
    X-XFCE-Commands=kitty
    X-XFCE-CommandsWithParameter=kitty --directory="%s"
  '';

  xdg.mimeApps = {
    enable = false;
  };
}

