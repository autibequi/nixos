{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # essentials
        unixtools.whereis
        coreutils-full
        pciutils
        gnumake
        lsof

        # office suite
        onlyoffice-bin

        # cli tools
        btop   # better top
        atuin  # fancy history

        # utils
        mission-center

        # Stuff
        steam
        obsidian
        stremio 
        sidequest # for oculus sideloading

        # media
        mpv

        # browsers 😒
        vivaldi  # for work
        brave    # for moi
        chromium # for testing

        # TESTING GROUND!
        # Nothing below this line is sacred
        # ---------------------------------

        deskreen # for remote screen sharing
        komorebi # for animated wallpapers

        # shells
        nushell
        fish

        # cli utils
        pueue

        # terminals
        ghostty
        alacritty

        # IDEs
        zed-editor

        # 3D Printing
        # cura # not working due python (using flatpak)
    ];
}