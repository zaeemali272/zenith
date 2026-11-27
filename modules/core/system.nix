{ config, pkgs, vars, ... }:

{
  time.timeZone = vars.timeZone;
  i18n.defaultLocale = vars.locale;
  systemd.oomd.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "net.core.default_qdisc" = "fq_codel";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  system.stateVersion = "26.05";
}
