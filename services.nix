{ config, pkgs, lib, ... } :

{
    # services
    services = {
        printing.enable = false;

        pipewire = {
            enable = true;
        };
    };

    # logitech drivers
    services.solaar.enable = true;

    # bluetooth
    services.blueman.enable = true;

    # flatpak
    services.flatpak.enable = true;

    # Bluetooth MPRIS Control
    # services.mpris-proxy.enable = true;
}