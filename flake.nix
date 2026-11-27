{
  description = "Zenith - Complete Dual-Distro Desktop Configuration & Flake (NixOS & Arch Linux)";

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

    zenith-shell = {
      url = "github:zaeemali272/zenith-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-dots = {
      url = "github:zaeemali272/Hyprland-dots";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell.url = "github:caelestia-dots/shell";
    caelestia-cli.url = "github:caelestia-dots/cli";

    end-4-dots = {
      url = "git+https://github.com/end-4/dots-hyprland.git?submodules=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, antigravity-nix, ... }@inputs:
    let
      vars = import ./vars.nix;

      # Every host is the same stack; they differ only in which
      # hardware-configuration.nix they carry.
      mkHost = hostPath: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars; };
        modules = [
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
      nixosConfigurations =
        let
          entries = builtins.readDir ./hosts;
          hostNames = builtins.filter (name: entries.${name} == "directory")
                                      (builtins.attrNames entries);
        in
          nixpkgs.lib.genAttrs hostNames (name: mkHost (./hosts + "/${name}"));
    };
}
