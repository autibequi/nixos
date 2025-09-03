{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # End of Day Update
  # https://nixos.wiki/wiki/Automatic_system_upgrades
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "16:00";
    randomizedDelaySec = "15min";
  };

  # Gambiarra pra rodar as coisas do jeito não nix
  # mostly vscode extensions.
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
    ];
  };

  # Adiciona a lib ao LD_LIBRARY_PATH para facilitar uso em ambientes Python/Poetry
  environment.sessionVariables.LD_LIBRARY_PATH = lib.mkAfter [
    "${pkgs.stdenv.cc.cc.lib}/lib"
  ];

  # Install LIX
  nix.package = pkgs.lix;

  # Unholy packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowImpure = true;

  # Apply nixGL overlay here, ensuring allowImpure is set on pkgs
  nixpkgs.overlays = lib.mkIf (inputs ? nixgl && inputs.nixgl ? overlay) [ inputs.nixgl.overlay ];

  # Configuração do Nix
  # Habilitar o uso de substitutos de cache
  # para acelerar o download de pacotes
  # e reduzir o uso de largura de banda
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nixpkgs-wayland.cachix.org"
      "https://nix-community.cachix.org/"
      "https://chaotic-nyx.cachix.org/"
      "https://hyprland.cachix.org"
      "https://anyrun.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
    ];

    # Enable experimental features
    experimental-features = [
      "nix-command"
      "flakes"
      "repl-flake"
    ];
  };

  # NH Tool
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 10";
    flake = "/etc/nixos";
  };
}
