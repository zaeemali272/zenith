{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.caskaydia-cove
    material-symbols
    rubik
  ];
}
