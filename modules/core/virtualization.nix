{ pkgs, ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };
    spiceUSBRedirection.enable = true;
    docker.enable = false;
  };

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

  # Allow guest VMs on the default bridge (virbr0) to communicate without firewall blocking DHCP/DNS
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  # Enable nested virtualization for both Intel and AMD CPUs
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_amd nested=1
  '';

  # Recommended VM utilities, guest tools, and viewers
  environment.systemPackages = with pkgs; [
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    guestfs-tools
    dnsmasq
    dmidecode
  ];
}
