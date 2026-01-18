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
    voxtype.url = "github:peteonrails/voxtype";
    nixified-ai.url = "github:nixified-ai/flake"; # Nixified AI

    hyprland.url = "github:hyprwm/Hyprland";

    hyprtasking = {
      url = "github:raybbian/hyprtasking";
      inputs.hyprland.follows = "hyprland";
    };

    # winboat = {
    #   url = "github:TibixDev/winboat";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
      nixified-ai,
      voxtype,
      ...
    }@inputs:
      let
      system = "x86_64-linux";
      # Configure the unstable channel to allow unfree packages
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.nomad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.allowInsecure = true;
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

          # Nixified AI - ComfyUI + Stable Diffusion
          nixified-ai.nixosModules.comfyui

          # Voxtype
          voxtype.nixosModules.default

          # Mine
          ./configuration.nix
        ];
      };
    };
}
