{ pkgs, ... }: 

{ 
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    ffmpeg
    gcr
    cliphist
    wl-clipboard
    geoclue2
    gammastep
    awww
    docker
    libnotify
    libappindicator-gtk3
    motrix-next
    aria2
    matugen
  ]; 
}