{ pkgs, ... }:

{
  nix.settings.auto-optimise-store = true;

  # nix.gc is deliberately not set here. programs.nh.clean in nh.nix already
  # collects the store on a schedule with an explicit retention policy, and
  # running both means two timers deleting the same generations.
}
