{ pkgs, ... }: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "zenith";
      theme_background = false;
      truecolor = true;
    };
  };
}
