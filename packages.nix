{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # warp?

        # essentials
        vim
        wget
        git
        zsh
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
        httpie

        # Gnome Stuff
        desktop-file-utils

        # Extensions
        gnomeExtensions.just-perfection
        gnomeExtensions.caffeine
        gnomeExtensions.forge
        gnomeExtensions.pano
        gnomeExtensions.appindicator
        gnomeExtensions.gsconnect
        gnomeExtensions.blur-my-shell
        
        # ai shit
        github-copilot-cli

        #NVIDIA?
        gnomeExtensions.gpu-profile-selector

        
    ];
}