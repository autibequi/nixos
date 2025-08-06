{
  description = "A very basic flake";
  inputs = {
    # Nix Channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Other Inputs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # Hardware
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    isd.url = "github:isd-project/isd"; # Interactive SystemD
    home-manager.url = "github:nix-community/home-manager/release-25.05"; # Home Manager
    nixified-ai.url = "github:nixified-ai/flake"; # Nixified AI

    hyprland.url = "github:hyprwm/Hyprland";

    hyprtasking = {
      url = "github:raybbian/hyprtasking";
      inputs.hyprland.follows = "hyprland";
    };
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

          # CachyOS Kernel
          chaotic.nixosModules.nyx-cache
          chaotic.nixosModules.nyx-overlay
          chaotic.nixosModules.nyx-registry

          # Unstable channel
          {
            nixpkgs.overlays = [
              (self: super: {
                unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
              })
            ];
          }

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
