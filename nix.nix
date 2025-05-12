{

  # Unholy packages
  nixpkgs.config.allowUnfree = true;

  # Configuração do Nix
  # Habilitar o uso de substitutos de cache
  # para acelerar o download de pacotes
  # e reduzir o uso de largura de banda
  nix.settings = {
    substituters = [
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://cache.nixos.org/"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "aseipp-nix-cache.global.ssl.fastly.net-1:0x2a3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f3g4h5i6j7k8l9m0n="
    ];
  };

  # Experimental Features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Habilitar Garbage Collector automático
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 10d";
  };

  # Habilitar o uso de todos os núcleos disponíveis
  nix.settings = {
    max-jobs = "auto";
    cores = 0; # usar todos os cores disponíveis
    sandbox = true;
    auto-optimise-store = true;
  };
}
