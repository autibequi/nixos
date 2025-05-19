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
        fastfetch

        # libs
        lz4

        # cli tools
        yt-dlp
        btop-rocm   # better top with amd support
        rocmPackages.rocm-smi
        libnotify # cli notifications
        jq          # json parser

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
        obsidian
        # cura

        # Aesthetics
        # Cursors
        banana-cursor
        apple-cursor
        bibata-cursors
        oreo-cursors-plus
        # Icons
        papirus-icon-theme

        # TESTING!
        mangohud
        blanket
    ];
}