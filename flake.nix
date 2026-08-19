{
  description = "Zenith - Universal Frost-Phoenix Style NixOS & Hyprland Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix.url = "github:jacopone/antigravity-nix";
    hermes-agent.url = "github:NousResearch/hermes-agent";

    zenith-shell = {
      url = "github:zaeemali272/zenith-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-dots = {
      url = "github:zaeemali272/Hyprland-dots";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hermes-agent, zen-browser, antigravity-nix, ... }@inputs:
    let
      vars = import ./vars.nix;

      # Every host is the same stack; they differ only in which
      # hardware-configuration.nix they carry.
      mkHost = hostPath: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars; };
        modules = [
          hermes-agent.nixosModules.default
          hostPath
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs vars; };
            home-manager.users.${vars.user} = import ./modules/home/default.nix;
          }
        ];
      };
    in rec {
      # Hosts are discovered from ./hosts rather than listed here.
      #
      # Anyone using this config adds hosts/<their-machine>/ and rebuilds; they
      # never edit this file. That matters for a shared repo: flake.nix is
      # something upstream changes, so every user edit to it becomes a merge
      # conflict on the next pull. A new directory conflicts with nothing.
      #
      # `nixos-rebuild switch --flake .` picks the entry matching the current
      # hostname automatically.
      nixosConfigurations =
        let
          entries = builtins.readDir ./hosts;
          hostNames = builtins.filter (name: entries.${name} == "directory")
                                      (builtins.attrNames entries);
        in
          nixpkgs.lib.genAttrs hostNames (name: mkHost (./hosts + "/${name}"));
    };
}
