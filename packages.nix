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

        # office suite
        onlyoffice-bin

        # cli tools
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

        # utils
        mission-center
        # obsidian
        yt-dlp
        lact

        # Games
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

    programs.zsh = {
        shellAliases = {
            history = "atuin";
            tasks = "pueue";
            find = "fzf";
            grep = "rg"; # ripgrep
            findf = "fd";
            cat = "bat";
            ls = "eza -la";
            du = "dust";
            ps = "procs";
            tree = "broot";
            cd = "z";
            man = "tldr";
        };

        # Init some of those alias
        shellInit = ''
            eval "$(zoxide init zsh)"
            eval "$(atuin init zsh)"
        '';
    };
}