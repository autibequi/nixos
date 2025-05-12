{

  # Unholy packages
  nixpkgs.config.allowUnfree = true;

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
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
    ];
  };

  # Experimental Features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Habilitar o uso de todos os núcleos disponíveis
  nix.settings = {
    max-jobs = "auto";
    cores = 0; # usar todos os cores disponíveis
    sandbox = true;
    auto-optimise-store = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 10";
  };
}
