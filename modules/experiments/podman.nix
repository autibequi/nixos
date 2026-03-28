{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.containers.containersConf.settings.engine.runtime = "crun";

  environment.sessionVariables.DOCKER_HOST = "unix:///run/podman/podman.sock";

  environment.systemPackages = with pkgs; [
    crun
    podman-compose
    lazydocker
    dive
  ];
}
