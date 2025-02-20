{ config, pkgs, lib, ... } :

{
    services = {
        # Cloudflare
        cloudflare-warp.enable = true;

        # Services
        printing.enable = false;

        pipewire = {
            enable = true;
        };
    };

    # Logitech drivers
    services.solaar.enable = true;

    # Bluetooth MPRIS Control
    # services.mpris-proxy.enable = true;
}