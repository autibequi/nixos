{ config, pkgs, lib, ... } :

{
    # Services
    services = {
        printing.enable = false;

        pipewire = {
            enable = true;
        };
    };

    # Logitech drivers
    services.solaar.enable = true;

    # bluetoot
    services.blueman.enable = true;

    # Bluetooth MPRIS Control
    # services.mpris-proxy.enable = true;
}