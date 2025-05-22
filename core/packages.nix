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
        pv

        # AMD
        lact
        rocmPackages.rocm-smi

        # cli tools
        yt-dlp
        btop-rocm   # better top with amd support
        libnotify # cli notifications
        jq          # json parser
        lz4         # compression

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
        tealdeer    # better tldr
        wl-clipboard # clipboard

        # shells
        nushell
        starship
        fish
        ghostty # terminals

        # apps
        mpv
        onlyoffice-bin
        brave
        mission-center
        sidequest # for oculus sideloading
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
        # openai-whisper-cpp
        # whisper-cpp
        # whisper-cpp-vulkan # Voice-To-Text - for blurt gnome extension
    ];
}