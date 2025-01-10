{ config, pkgs, lib, ... } :

{
    services = {
        # Cloudflare
        cloudflare-warp.enable = true;

        # Services
        printing.enable = false;
        gnome.gnome-browser-connector.enable = true;
        flatpak.enable = true;

        pipewire = {
            enable = true;
        };
    };

    # Logitech drivers
    services.solaar.enable = true;

    # Flatpak Repo
    systemd.services.flatpak-repo = {
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.flatpak ];
        script = ''
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
    };
}