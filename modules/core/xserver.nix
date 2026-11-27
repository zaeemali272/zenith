{ pkgs, vars, ... }:

{
  services.xserver.enable = false;
  services.xserver.xkb.layout = vars.keyboardLayout;
}
