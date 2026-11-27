{ pkgs, ... }:

let
  # Finds whichever charge-limit attribute this laptop exposes and hands it to
  # the wheel group. Written once and used by both the udev rule and the boot
  # service, so the two can never drift apart.
  grantBatteryCare = pkgs.writeShellScript "grant-battery-care" ''
    set -u
    for node in \
      /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode \
      /sys/class/power_supply/*/charge_control_end_threshold \
      /sys/class/power_supply/*/charge_control_start_threshold; do
      [ -e "$node" ] || continue
      ${pkgs.coreutils}/bin/chgrp wheel "$node" 2>/dev/null || true
      ${pkgs.coreutils}/bin/chmod g+w   "$node" 2>/dev/null || true
    done
  '';
in
{
  # Battery charge limiting, writable without a password.
  #
  # The kernel exposes these as root-owned sysfs attributes, so a desktop toggle
  # otherwise has to go through pkexec and prompt for a password every time --
  # for a setting you flip as casually as a brightness slider. Worse, with no
  # polkit agent running it fails silently and the button appears dead.
  #
  # Handled two ways on purpose:
  #
  #   udev    catches the device appearing, including after a module reload or
  #           a resume, which is when permissions would otherwise revert.
  #   systemd catches the case where the device was already present before the
  #           rules were installed -- i.e. the very first boot after enabling
  #           this, where a udev rule alone would do nothing until you rebooted
  #           a second time.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="platform", KERNEL=="VPC2004:00", RUN+="${grantBatteryCare}"
    ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", RUN+="${grantBatteryCare}"
  '';

  systemd.services.battery-care-permissions = {
    description = "Allow the wheel group to set the battery charge limit";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = grantBatteryCare;
    };
  };
}
