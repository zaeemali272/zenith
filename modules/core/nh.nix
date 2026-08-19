{ pkgs, vars, ... }:

{
  programs.nh = {
    enable = true;

    # Garbage collection is nh's job here. nix.gc in clean.nix was also enabled,
    # so the store was being collected twice on different schedules by two
    # mechanisms that did not know about each other. This one is kept because it
    # is the one with a considered retention policy.
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";

    # This used to be "/home/${vars.user}/zenith-nixos", which does not exist --
    # the repository is one directory deeper. NH_FLAKE was therefore pointing at
    # nothing, and a bare `nh os switch` could not work.
    flake = vars.configDir or "/home/${vars.user}/zenith/zenith-nixos";
  };
}
