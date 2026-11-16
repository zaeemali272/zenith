{ pkgs, ... }: {
  home.packages = with pkgs; [
    anydesk
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
    proton-vpn
  ];
}

