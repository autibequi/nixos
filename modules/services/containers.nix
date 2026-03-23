{ config, lib, pkgs, ... }:
let
  cfg = config.local.containers;
  isPodman = cfg.engine == "podman";
in {
  options.local.containers = {
    engine = lib.mkOption {
      type = lib.types.enum [ "podman" "docker" ];
      default = "docker";
      description = "Container engine. Swap between podman and docker with a single toggle.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf isPodman {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      environment.sessionVariables.DOCKER_HOST = "unix:///run/podman/podman.sock";
      environment.systemPackages = [ pkgs.podman-compose ];
    })

    (lib.mkIf (!isPodman) {
      virtualisation.docker = {
        enable = true;
        enableOnBoot = false;
      };
      environment.systemPackages = [ pkgs.docker-compose ];
    })

    {
      environment.systemPackages = with pkgs; [ lazydocker dive ];
    }
  ];
}
