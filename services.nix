{ config, pkgs, lib, ... } :

{
    services = {
        # Cloudflare
        cloudflare-warp.enable = true;

        # Services
        printing.enable = false;
        gnome.gnome-browser-connector.enable = true;
        # flatpak.enable = true;

        pipewire = {
            enable = true;
        };
    };

    # Logitech drivers
    services.solaar.enable = true;
}