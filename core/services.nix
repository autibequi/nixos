{ config, pkgs, lib, ... } :

{
    # Disable Evil Printer
    services.printing.enable = false;

    # logitech drivers
    services.solaar.enable = true;

    # flatpak
    services.flatpak.enable = true;

    # Enable Docker
    virtualisation.docker.enable = true;

    # Preload common apps for snappier experience
    services.preload.enable = true;

    # CPU Power Management
    services.cpupower-gui.enable = true;

    # LACT Daemon
    # lact is a daemon that allows you to control the AMD GPU power states
    systemd.services.lact = {
        description = "AMDGPU Control Daemon";
        after = ["multi-user.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
            ExecStart = "${pkgs.lact}/bin/lact daemon";
        };
        enable = true;
    };

    # Podman (not working yet)
    # virtualisation.podman = {
    #     enable = true;
    #     dockerCompat = true;

    #     # Required for containers under podman-compose to be able to talk to each other.
    #     defaultNetwork.settings.dns_enabled = true;
    # };


    # environment.systemPackages = with pkgs; [
    #     dive # look into docker image layers
    #     podman-tui # status of containers in the terminal
    #     podman-compose
    # ];

    # # Ensure Podman uses docker.io as the default registry
    # environment.etc."containers/registries.conf".text = lib.mkForce ''
    #     unqualified-search-registries = ["docker.io"]
    # '';
}