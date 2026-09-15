{ config, pkgs, ... }:

{
  programs.librewolf = {
    enable = true;
    # Optional preference overrides & persistence configuration
    settings = {
      "webgl.disabled" = false;
      "privacy.resistFingerprinting" = false;

      # Prevent LibreWolf from wiping cookies, history, and active sessions on shutdown/rebuild
      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.cookies" = false;
      "privacy.clearOnShutdown.sessions" = false;
      "privacy.clearOnShutdown.offlineApps" = false;
      "privacy.sanitizeOnShutdown" = false;
    };
  };
}
