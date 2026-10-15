{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;
    
    extraCompatPackages = with pkgs; [
      proton-ge-bin
      wine
      winetricks
      wineWowPackages.stable
    ];
  };

  programs.gamemode.enable = true;
  hardware.graphics.enable32Bit = true;
}
