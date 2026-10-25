{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = false;
  virtualisation.docker.enable = false;
  programs.virt-manager.enable = false;
}
