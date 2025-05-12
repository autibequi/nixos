{ config, pkgs, lib, ... } :

{
    # Disable Evil Printer
    services.printing.enable = false;

    # logitech drivers
    services.solaar.enable = true;

    # flatpak
    services.flatpak.enable = true;

    # Docker
    virtualisation.docker.enable = true;
}