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
        # ai shit
        github-copilot-cli

        # TODO:Test
        nushell
        pueue
        starship
        zed-editor
    ];
}