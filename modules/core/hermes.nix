{ config, pkgs, ... }:

{
  services.hermes-agent = {
    enable = false;
    addToSystemPackages = false;
  };
}