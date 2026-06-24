{
  description = "A very basic flake";

  # Caches configurados canonicamente em modules/system/nix.nix (nix.settings)
  # nixConfig aqui seria redundante — accept-flake-config = true já está lá

  inputs = {
    # Nix Channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Other Inputs
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      # follows: nixos-hardware é só módulos (não builda nada), então seguir o nixpkgs
      # principal elimina o nixpkgs duplicado no lock sem custo de cache.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CacheNix
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Claude Code (sadjow) — sempre na última versão upstream
    claude-code.url = "github:sadjow/claude-code-nix";

    # Zed Editor — pin na tag preview (canal beta). Sem follows de propósito:
    # usa o nixpkgs próprio do flake do Zed pra bater bit-a-bit com o CI e ter
    # cache hit no zed.cachix.org (sem isso, compila o Rust localmente).
    # Atualizar pra próxima preview: trocar a tag e rodar `nix flake update zed`.
    zed.url = "github:zed-industries/zed/v1.9.0-pre";

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

    # AI coding agents — sem follows: usa nixpkgs-unstable próprio pra garantir hits no cache deles
    llm-agents.url = "github:numtide/llm-agents.nix";

  };

  # Outputs
  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      chaotic,
      claude-code,
      zed,
      dms,
      hyprlandFlake,
      llm-agents,
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
          # GA402X + NVIDIA (shared.nix impõe mem_sleep_default=deep — overridden em modules/boot/hibernate.nix)
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
