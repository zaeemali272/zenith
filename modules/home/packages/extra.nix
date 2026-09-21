{ pkgs, inputs, ... }:

{
  home.packages = [
    (pkgs.element-desktop.override {
      commandLineArgs = "--ozone-platform=x11";
    })
    pkgs.pear-desktop
    inputs.thorium.packages.${pkgs.stdenv.hostPlatform.system}.thorium-avx
    pkgs.proton-vpn
    pkgs.cameractrls
  ];
}

