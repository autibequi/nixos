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

    # DankMaterialShell — usa unstable porque o stable 25.11 não tem dms-shell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Hyprland — sempre na última versão upstream
    hyprlandFlake = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  # Outputs
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      chaotic,
      claude-code,
      dms,
      hyprlandFlake,
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
        specialArgs = {
          inherit inputs unstable;
          hyprlandFlake = hyprlandFlake.packages.${system};
        };
        modules = [
          # GA402X + NVIDIA (shared.nix impõe mem_sleep_default=deep — overridden em modules/core/hibernate.nix)
          nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia

          # CachyOS Kernel
          chaotic.nixosModules.default

          # Claude Code (sadjow) — overlay substitui pkgs.claude-code pela última versão upstream
          { nixpkgs.overlays = [ claude-code.overlays.default ]; }

          # DankMaterialShell — NixOS module do flake (stable 25.11 não tem no nixpkgs)
          dms.nixosModules.default

          # Mine
          ./configuration.nix
        ];
      };
    };
}
