{ pkgs, inputs, ... }:

{
  home.packages = [
    (pkgs.element-desktop.override {
      commandLineArgs = "--ozone-platform=x11";
    })
    pkgs.pear-desktop
    inputs.thorium.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.proton-vpn
  ];
}

