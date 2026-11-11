{ pkgs, config, lib, vars, ... }:

{
  # 1. Open ports for NectarLink:
  #    - 7718 TCP/UDP: Main QUIC / TLS transport & control
  #    - 5353 UDP: mDNS discovery for finding phones/PCs on LAN
  #    - 53317 TCP/UDP: LocalSend compatibility layer
  networking.firewall = {
    allowedTCPPorts = [ 7718 53317 ];
    allowedUDPPorts = [ 7718 5353 53317 ];
  };

  # 2. Virtual input (allows controlling PC mouse and keyboard from the phone)
  hardware.uinput.enable = true;

  # 3. Phone as Webcam via v4l2loopback
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    kernelModules = [ "v4l2loopback" "uinput" ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="NectarLink Webcam" exclusive_caps=1
    '';
  };

  # 4. ADB tools for USB pairing and Elevated wireless debugging
  environment.systemPackages = [ pkgs.android-tools ];

  # 5. User permissions for uinput devices
  users.users.${vars.user}.extraGroups = [ "uinput" ];
}
