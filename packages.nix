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
        stremio

        # Utils
        gnumake
        coreutils-full
        atuin

        # TODO:Test
        nushell
        pueue
        starship
        zed-editor

        #cliiiiiii
        btop   # better top
        lsof

        # browsers
        vivaldi
        brave
        chromium
    ];
}