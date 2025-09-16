{ config, pkgs, ... }:

{
  # Docker
  virtualisation.docker.enable = true;
  # Add user to docker group
  users.users.pedrinho.extraGroups = [ "docker" ];

  # Install docker-compose and lazydocker
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
  ];
} 
