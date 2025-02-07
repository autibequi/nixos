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

        # Xterm
        xserver.desktopManager.xterm.enable = false;
    };

    # Logitech drivers
    services.solaar.enable = true;
}