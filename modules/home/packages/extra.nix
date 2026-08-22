{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (element-desktop.override {
      commandLineArgs = "--ozone-platform=x11";
    })
    pear-desktop
    google-chrome
  ];
}

