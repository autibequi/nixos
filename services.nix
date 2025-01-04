{ config, pkgs, lib, ... } :

{
    services = {
        # Services
        printing.enable = false;
        gnome.gnome-browser-connector.enable = true;
        cloudflare-warp.enable = true;
        flatpak.enable = true;
    };

    # Flatpak Repo
    systemd.services.flatpak-repo = {
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.flatpak ];
        script = ''
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
    };
}