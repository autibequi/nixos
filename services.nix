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

        # Xterm
        xserver.desktopManager.xterm.enable = false;
    };

    # Logitech drivers
    services.solaar.enable = true;

    # AIIIIIIIIIII
    services.ollama = {
        enable = true;
        acceleration = "cuda";
    };
}