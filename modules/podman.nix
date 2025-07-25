{ pkgs, ... }:

{
  # Habilita containers com podman seguindo documentação oficial
  virtualisation = {
    containers = {
      enable = true;
      registries.search = [
        "docker.io"
        "quay.io"
        "registry.fedoraproject.org"
        "ghcr.io"
        "registry.gitlab.com"
      ];
    };

    podman = {
      enable = true;
      # Cria alias `docker` para podman como drop-in replacement
      dockerCompat = true;
      # Necessário para containers do podman-compose se comunicarem
      defaultNetwork.settings.dns_enabled = true;
    };

    # Configuração para rodar containers como serviços systemd
    oci-containers = {
      backend = "podman";
      # Exemplo de container como serviço (descomente e configure conforme necessário)
      # containers = {
      #   exemplo-container = {
      #     image = "nginx:alpine";
      #     autoStart = true;
      #     ports = [ "127.0.0.1:8080:80" ];
      #   };
      # };
    };
  };

  # Cria o grupo podman
  users.groups.podman = {};

  # Configuração de usuário para podman rootless
  users.users."pedrinho" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "podman" ];
    # Configuração automática de subUIDs/subGIDs (NixOS gerencia automaticamente)
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # Ferramentas úteis para desenvolvimento com containers
  environment.systemPackages = with pkgs; [
    dive # inspecionar camadas de imagens docker
    podman-tui # status de containers no terminal
    podman-compose # iniciar grupo de containers para desenvolvimento
  ];
}
