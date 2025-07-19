{
  pkgs,
  ...
}:

{
  # Enable containers with podman
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
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      extraPackages = with pkgs; [
        podman-compose
        dive
        podman-tui
      ];
    };
  };

  # Container Tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    podman-compose # start group of containers for dev
    docker-compose # fallback docker compose
  ];
}
