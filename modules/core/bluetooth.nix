{ pkgs, vars, ... }:

{
  hardware.bluetooth.enable = vars.hasBluetooth;
  hardware.bluetooth.powerOnBoot = true;
}
