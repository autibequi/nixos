{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # essentials
        uutils-coreutils
        unixtools.whereis
        pciutils
        gnumake
        lsof
        usbutils
        lnav

        # cli tools
        yt-dlp
        btop-rocm   # better top with amd support
        rocmPackages.rocm-smi

        # better cli
        atuin       # fancy cli history
        pueue       # task manager
        fzf         # fuzzy finder
        ripgrep     # better grep
        fd          # better find
        bat         # better cat
        eza         # better ls
        dust        # better du
        procs       # better ps
        broot       # better tree
        zoxide      # better cd
        tealdeer    # better tldr

        # shells
        nushell
        starship

        # terminals
        ghostty
        alacritty

        # apps
        mpv
        onlyoffice-bin
        brave
        mission-center
        sidequest # for oculus sideloading
        lact
        stremio 
        # obsidian
        # 3D Printing
        # cura # not working due python (using flatpak)

        # Aesthetics
        banana-cursor
        apple-cursor
        bibata-cursors
        oreo-cursors-plus

        # TESTING!
        mangohud
        blanket
        themechanger
    ];
}