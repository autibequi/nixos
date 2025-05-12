{ config, pkgs, lib, ... } :

{
    # services
    services = {
        printing.enable = false;
    };

    # logitech drivers
    services.solaar.enable = true;

    # flatpak
    services.flatpak.enable = true;
}