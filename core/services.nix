{ config, pkgs, lib, ... } :

{
    # Disable Evil Printer
    services.printing.enable = false;

    # logitech drivers
    services.solaar.enable = true;

    # flatpak
    services.flatpak.enable = true;

    # Enable Docker
    virtualisation.docker.enable = true;

    # Preload common apps for snappier experience
    services.preload.enable = true;

    # CPU Power Management
    services.cpupower-gui.enable = true;

}