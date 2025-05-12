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
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # Experimental Features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Habilitar Garbage Collector automático
  nix.gc = {
    automatic = true;
    options = "--delete-generations-old 20";
  };

  # Habilitar o uso de todos os núcleos disponíveis
  nix.settings = {
    max-jobs = "auto";
    cores = 0; # usar todos os cores disponíveis
    sandbox = true;
    auto-optimise-store = true;
  };
}
