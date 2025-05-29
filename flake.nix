{
  description = "A very basic flake";
  inputs = {
    # Nix Channels
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Other Inputs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # Hardware
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    isd.url = "github:isd-project/isd"; # Interactive SystemD
    home-manager.url = "github:nix-community/home-manager/release-25.05"; # Home Manager
    solaar.url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # Logitech Solaar
    nixpkgs-howdy.url = "github:NixOS/nixpkgs/pull/216245/head";
    nix-alien.url = "github:thiagokokada/nix-alien";
    stylix.url = "github:danth/stylix";
    nixgl.url = "github:nix-community/nixGL";
    nixified-ai = {
      url = "github:nixified-ai/flake";
    };
  };

  # Outputs
  # This is the default output, which is a set of attributes.
  outputs =
    {
      self,
      nixpkgs,
      solaar,
      nixos-hardware,
      home-manager,
      chaotic,
      nixos-cosmic,
      nix-alien,
      stylix,
      nixgl,
      ...
    }@inputs:
    {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
      packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

      nixosConfigurations.nomad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; # Pass all inputs to modules
        modules = [
          # Currenct Laptop Flake
          nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia

          # Logitech Solaar
          solaar.nixosModules.default

          # CachyOS Kernel
          chaotic.nixosModules.nyx-cache
          chaotic.nixosModules.nyx-overlay
          chaotic.nixosModules.nyx-registry

          # Cosmic
          nixos-cosmic.nixosModules.default

          # Stylix
          stylix.nixosModules.stylix

          # NixAlien
          (
            { self, system, ... }:
            {
              environment.systemPackages = with self.inputs.nix-alien.packages.${system}; [
                nix-alien
              ];
              # Optional, needed for `nix-alien-ld`
              programs.nix-ld.enable = true;
            }
          )

          # home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Add this inside home configuration block (without this it won't work):
            home-manager.extraSpecialArgs = {
              nixgl = nixgl;
            };
          }

          # Interactive SystemD
          {
            environment.systemPackages = [ inputs.isd.packages.x86_64-linux.default ];
          }

          # Mine
          ./configuration.nix
        ];
      };
    };
}
