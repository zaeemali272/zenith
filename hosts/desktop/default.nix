# Generic host for anyone using this configuration.
#
# This used to try to pick up the building machine's own hardware config:
#
#   (if builtins.pathExists "/etc/nixos/hardware-configuration.nix"
#    then /etc/nixos/hardware-configuration.nix
#    else ./hardware-configuration.nix)
#
# That never worked. `nixos-rebuild --flake` evaluates in pure mode, where
# builtins.pathExists on an absolute path outside the flake returns false even
# when the file is right there -- verified with
# `nix eval --expr 'builtins.pathExists "/etc/nixos/hardware-configuration.nix"'`,
# which prints false pure and true with --impure. So the check silently took
# the else branch and applied the repo author's disk UUIDs to every machine
# that built it, which is what put other people into emergency mode.
#
# There is no pure way to read /etc/nixos, so the file is supplied per machine
# instead, and ships as a placeholder that throws with instructions.
{ config, pkgs, vars, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  networking.hostName = vars.hostname;

  # Caught here rather than on the author's host, which legitimately uses these
  # values. Without this, someone who cloned the repo and rebuilt without
  # touching vars.nix would silently get an account named "zaeem" with the
  # author's git identity, and none for themselves.
  assertions = [
    {
      assertion = vars.user != "zaeem";
      message = ''
        vars.nix still has the repo author's identity (user = "zaeem").

        Edit vars.nix and set at least user, fullName, email and hostname to
        your own before building .#desktop -- otherwise this configuration
        creates an account for someone else and none for you.
      '';
    }
  ];
}
