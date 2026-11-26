{ pkgs, ... }:

{
  home.packages = [
    (pkgs.element-desktop.override {
      commandLineArgs = "--ozone-platform=x11";
    })
    pkgs.pear-desktop
    pkgs.cameractrls
    pkgs.wineWow64Packages.stable
    pkgs.winetricks
  ];
}

