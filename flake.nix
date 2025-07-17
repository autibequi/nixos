{
  description = "A very basic flake";
  inputs = {
    # Nix Channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Other Inputs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # Hardware
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    isd.url = "github:isd-project/isd"; # Interactive SystemD
    home-manager.url = "github:nix-community/home-manager/release-25.05"; # Home Manager
    solaar.url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # Logitech Solaar
    nixified-ai.url = "github:nixified-ai/flake"; # Nixified AI
  };

  # Outputs
  outputs =
    {
      self,
      nixpkgs,
      solaar,
      nixos-hardware,
      home-manager,
      chaotic,
      # nixified-ai,
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

          # home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }

          # Nixified AI
          # nixified-ai.nixosModules.default

          # Mine
          ./configuration.nix
        ];
      };
    };
}
