{ pkgs, ... }:

{
  # Battery charge limiting, writable without a password prompt.
  #
  # The kernel exposes these as root-owned sysfs attributes, so a desktop toggle
  # otherwise has to go through pkexec and ask for a password every single time
  # -- for a setting you flip as casually as a brightness slider. These rules
  # hand write access to the wheel group instead.
  #
  # Two families are covered: Lenovo ideapad's conservation_mode, and the
  # generic charge_control_end_threshold most other laptops use.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="platform", KERNEL=="VPC2004:00", \
      RUN+="${pkgs.bash}/bin/sh -c 'chgrp wheel /sys/$devpath/conservation_mode && chmod g+w /sys/$devpath/conservation_mode'"

    ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", \
      RUN+="${pkgs.bash}/bin/sh -c 'test -e /sys/$devpath/charge_control_end_threshold && chgrp wheel /sys/$devpath/charge_control_end_threshold && chmod g+w /sys/$devpath/charge_control_end_threshold || true'"
  '';
}
