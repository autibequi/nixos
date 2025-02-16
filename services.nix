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

    # Bluetooth MPRIS
    # services.mpris-proxy.enable = true; # after 25.05 home-manager
    systemd.user.services.mpris-proxy = {
        description = "Mpris proxy";
        after = [ "network.target" "sound.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
}