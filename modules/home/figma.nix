{ pkgs, ... }:

{
  home.packages = with pkgs; [
    figma-linux
    figma-agent
  ];
}
