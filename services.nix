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

    # Audio
    hardware.pulseaudio.extraConfig = "
        load-module module-switch-on-connect
    ";

    # Logitech drivers
    services.solaar.enable = true;
}