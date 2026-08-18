# Zaeem's machine.
#
# This is the only host in the repo that carries real hardware-configuration.nix
# contents, because those describe physical disks by UUID and are true for
# exactly one computer. Anyone else should build .#desktop and supply their own.
{ config, pkgs, vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  networking.hostName = "V14";
}
