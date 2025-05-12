{

  # Unholy packages
  nixpkgs.config.allowUnfree = true;

  # Configuração do Nix
  # Habilitar o uso de substitutos de cache
  # para acelerar o download de pacotes
  # e reduzir o uso de largura de banda
  nix.settings = {
    substituters = [
      "https://cosmic.cachix.org/" 
      "https://chaotic-nyx.cachix.org/"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" 
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
      "aseipp-nix-cache.global.ssl.fastly.net-1:0x2a3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f3g4h5i6j7k8l9m0n="
      "chaotic-nyx.cachix.org-1:0x2a3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f3g4h5i6j7k8l9m0n="
      "nixos-unstable.cachix.org-1:0x2a3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f3g4h5i6j7k8l9m0n="
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
