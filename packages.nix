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
        btop-rocm   # better top with amd support
        atuin       # fancy cli history
        pueue       # task manager

        # shells
        nushell
        fish
        starship

        # terminals
        ghostty
        alacritty

        # utils
        mission-center
        obsidian
        yt-dlp

        # Games
        steam
        sidequest # for oculus sideloading

        # media
        mpv
        stremio 

        # browsers 😒
        vivaldi  # for work
        brave    # for moi
        chromium # for testing

        # TESTING GROUND!
        # Nothing below this line is sacred
        # ---------------------------------
        deskreen # for wireless screen mirroring

        # IDEs
        zed-editor

        # 3D Printing
        # cura # not working due python (using flatpak)
    ];

    
}