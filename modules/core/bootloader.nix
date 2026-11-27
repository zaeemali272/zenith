{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;

  # Without a limit every generation keeps its kernel and initrd on the ESP,
  # which is a fixed-size FAT partition. It fills up quietly and then a rebuild
  # fails at the very end, with the system already half-switched.
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.tmp.cleanOnBoot = true;

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "systemd.show_status=auto"
    "vt.global_cursor_default=0"
  ];
}
