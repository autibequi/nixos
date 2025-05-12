{ config, pkgs, lib, ... } :

{
    # Disable Evil Printer
    services.printing.enable = false;

    # logitech drivers
    services.solaar.enable = true;

    # flatpak
    services.flatpak.enable = true;

    # Docker/Podman
    virtualisation.podman = {
        enable = true;
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
    };


    environment.systemPackages = with pkgs; [
        dive # look into docker image layers
        podman-tui # status of containers in the terminal
        podman-compose
    ];

    # Ensure Podman uses docker.io as the default registry
    environment.etc."containers/registries.conf".text = lib.mkForce ''
        [registries.search]
        registries = ['docker.io']
    '';
}