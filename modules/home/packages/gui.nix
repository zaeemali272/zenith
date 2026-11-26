{ pkgs, ... }: {
  home.packages = with pkgs; [
    anydesk
    brave-origin
    eog
    zed-editor
    file-roller
    mpv
    mpvScripts.uosc
    mpvpaper
    hicolor-icon-theme
    qpwgraph
    pavucontrol
    onlyoffice-desktopeditors
    losslesscut
    proton-vpn
    vesktop
  ];
}

