{ config, pkgs, ... }:

{
  programs.floorp = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
      };
    };
  };
}
