{ pkgs, ... }: {
  home.packages = with pkgs; [
    brave-origin-bin
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

