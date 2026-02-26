{ config, lib, pkgs, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;

    # Socket activation: docker.service only starts when the socket is first used,
    # removing it from the critical boot path entirely.
    enableOnBoot = false;
  };

  # Install docker-compose and lazydocker
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
  ];
}
