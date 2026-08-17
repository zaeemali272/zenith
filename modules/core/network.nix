{ pkgs, ... }:

{
  networking.firewall.enable = true;
  networking.firewall.checkReversePath = false;  
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}
