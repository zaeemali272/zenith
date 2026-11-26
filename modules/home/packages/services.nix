{ pkgs, ... }: 

{ 
  home.packages = with pkgs; [
    brightnessctl
    playerctl
    ffmpeg
    gcr
    cliphist
    wl-clipboard
    hyprsunset
    awww
    libnotify
    libappindicator-gtk3
    motrix-next
    aria2
    matugen
  ]; 
}