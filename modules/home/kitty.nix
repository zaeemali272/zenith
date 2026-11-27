{ pkgs, ... }: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11.5;
    };
    settings = {
      # Styling & padding
      window_padding_width = "12 14";
      placement_strategy = "center";
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;

      # Translucency & blur
      background_opacity = "0.92";
      dynamic_background_opacity = "yes";
      background_blur = 8;

      # Cursor
      cursor_shape = "beam";
      cursor_beam_thickness = "1.8";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "15.0";

      # Multi-line pastes count as "control codes" and trigger a confirm
      # dialog on every paste; only warn on large ones and keep URLs quoted.
      paste_actions = "quote-urls-at-prompt,confirm-if-large";

      # Memory & buffer optimizations
      scrollback_lines = 3000;
      scrollback_pager_history_size = 0;

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "yes";

      # Tab bar
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "\"{index}: {title}\"";

      # Bell
      enable_audio_bell = "no";
      visual_bell_duration = "0.0";

      # Mouse
      url_style = "curly";
      open_url_with = "default";
      detect_urls = "yes";
      copy_on_select = "no";
    };

    extraConfig = ''
      # Dynamic Zenith theme colors (regenerated on wallpaper / accent changes)
      include ~/.cache/zenith/kitty-colors.conf
    '';
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

