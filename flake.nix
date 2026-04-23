{
  description = "A very basic flake";
  inputs = {
    # Nix Channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Other Inputs
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # CacheNix
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Claude Code (sadjow) — sempre na última versão upstream
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  # Outputs
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
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
      };
    in
    {
      nixosConfigurations.nomad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs unstable; };
        modules = [
          # GA402X + NVIDIA (shared.nix impõe mem_sleep_default=deep — overridden em modules/core/hibernate.nix)
          nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia

          # CachyOS Kernel
          chaotic.nixosModules.default

          # Claude Code (sadjow) — overlay substitui pkgs.claude-code pela última versão upstream
          { nixpkgs.overlays = [ claude-code.overlays.default ]; }

          # Mine
          ./configuration.nix
        ];
      };
    };
}
