{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.nectarlink.packages.${pkgs.stdenv.hostPlatform.system}.nectarlink
  ];
}
