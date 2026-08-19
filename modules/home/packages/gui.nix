{ pkgs, ... }: {
   home.packages = with pkgs; [
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
