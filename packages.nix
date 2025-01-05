{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # essentials
        vim
        wget
        unixtools.whereis
        mission-center
        pciutils

        # Stuff
        steam
        obsidian

        # Tools
        dbeaver-bin
        insomnia
        podman

        # Work/Estrategia
        cloudflare-warp
        chromium
        python314
        poetry
        vscode
        gradle
        go
        terraform

        # Node
        nodejs_23

        # Flutter
        flutter
        android-studio
        android-tools
        dart

        # Flatpaks
        flatpak

        # Utils
        gnumake
        coreutils-full
        atuin

        # Gnome Stuff
        desktop-file-utils
        gnome-extension-manager
        blackbox-terminal # due to gnome-terminal being removed

        # Extensions
        gnomeExtensions.just-perfection
        gnomeExtensions.caffeine
        gnomeExtensions.forge
        gnomeExtensions.pano
        gnomeExtensions.appindicator
        gnomeExtensions.gsconnect
        gnomeExtensions.blur-my-shell
        gnomeExtensions.auto-power-profile        
        #NVIDIA?
        gnomeExtensions.gpu-profile-selector      
        gnomeExtensions.battery-health-charging
        gnomeExtensions.vertical-workspaces

        # ai shit
        github-copilot-cli

        # TODO:Test
        nushell
        pueue
        starship
        zed-editor

        # hacking stuff
        dig
    ];

    # Gnome Debloat
    # Exclude Core Apps From Being Installed.
    environment.gnome.excludePackages = with pkgs.gnome; [
        pkgs.epiphany
        pkgs.gedit
        pkgs.totem
        pkgs.yelp
        pkgs.geary
        pkgs.gnome-calendar
        pkgs.gnome-contacts
        pkgs.gnome-maps
        pkgs.gnome-music
        pkgs.gnome-photos
        pkgs.gnome-tour
        pkgs.evince
        pkgs.gnome-weather
        pkgs.gnome-clocks
        pkgs.gnome-characters
        pkgs.gnome-sound-recorder
        pkgs.gnome-logs
        pkgs.gnome-usage
        pkgs.simple-scan
        pkgs.gnome-console
        pkgs.gnome-software
    ];
}