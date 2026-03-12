{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.sessionVariables.DOCKER_HOST = "unix:///run/podman/podman.sock";

  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
    dive
  ];
}
