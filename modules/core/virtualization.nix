{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  programs.virt-manager.enable = true;

  # libvirt ships a "default" NAT network but leaves it defined-and-stopped with
  # autostart off. Every VM created with the default networking then fails to
  # start with:
  #
  #   Requested operation is not valid: network 'default' is not active
  #
  # Marking it autostart and starting it here means that is handled once by the
  # system rather than by hand after every reboot. Both calls are tolerant of
  # already being done.
  systemd.services.libvirtd.postStart = ''
    ${pkgs.libvirt}/bin/virsh net-autostart default || true
    ${pkgs.libvirt}/bin/virsh net-start default || true
  '';
}
