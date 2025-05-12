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
      "https://chaotic-nyx.cachix.org/"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
      
    ];
    
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
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
