{ pkgs, ... }: { imports = [ ./cli.nix ./dev.nix ./gui.nix ./nix.nix ./services.nix ./extra.nix ]; }
