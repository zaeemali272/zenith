{ pkgs, ... }: {
  home.packages = with pkgs; [
    brave-origin
    eog
    zed-editor
    file-roller
    mpv
    mpvpaper
    hicolor-icon-theme
    qpwgraph
    onlyoffice-desktopeditors
    losslesscut
  ];
}

