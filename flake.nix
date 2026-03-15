{
  description = "A very basic flake";
  inputs = {
    # Nix Channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Other Inputs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # Hardware
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11"; # Home Manager
    claude-code.url = "github:sadjow/claude-code-nix";

  };

  # Outputs
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      home-manager,
      chaotic,
      claude-code,
      ...
    }@inputs:
      let
      system = "x86_64-linux";
      # Configure the unstable channel to allow unfree packages
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [ "openclaw-2026.2.26" ];
      };
    in
    {
      nixosConfigurations.nomad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs unstable; };
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ claude-code.overlays.default ];
          }

          # Currenct Laptop Flake
          nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia

          # CachyOS Kernel
          chaotic.nixosModules.default

          # home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }

          # Mine
          ./configuration.nix
        ];
      };
    };
}
