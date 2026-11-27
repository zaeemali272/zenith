{ config, pkgs, vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  networking.hostName = "vm";
}
