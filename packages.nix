{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # essentials
        unixtools.whereis
        coreutils-full
        pciutils
        gnumake

        # cli tools
        btop   # better top
        lsof
        atuin  # fancy history

        # utils
        mission-center

        # Stuff
        steam
        obsidian
        stremio

        # TODO:Test
        nushell
        pueue
        starship
        zed-editor

        # browsers 😒
        vivaldi  # for work
        brave    # for moi
        chromium # for testing
    ];
}