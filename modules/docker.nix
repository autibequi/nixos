{ config, lib, pkgs, ... }:

{
  # Docker
  virtualisation.docker.enable = true;

  # Install docker-compose and lazydocker
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
  ];
} 
