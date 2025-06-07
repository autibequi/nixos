{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    zsh-autoenv.enable = true;
    enableBashCompletion = true;
    autosuggestions.strategy = [ "match_prev_cmd" ];
    autosuggestions.highlightStyle = "fg=10";

    ohMyZsh.plugins = [
      "git"
      "sudo"
      "history"
      "history-substring-search"
      "completion"
      "colored-man-pages"
      "colored-ls"
      "command-not-found"
      "extract"
      "fzf"
      "zoxide"
    ];

    syntaxHighlighting.highlighters = [
      "main"
      "brackets"
      "pattern"
      "line"
      "cursor"
    ];

    shellAliases = {
      history = "atuin";
      tasks = "pueue";
      grep = "rg"; # ripgrep
      findf = "fd";
      cat = "bat";
      ls = "eza -la";
      du = "dust";
      ps = "procs";
      tree = "broot";
      cd = "z";
      f = "fzf --wrap";
      ff = "fastfetch";
      clip = "wl-copy";
      clipb = "wl-paste";
      zed = "zeditor";

      wiki = "wikiti";
    };

    shellInit = ''
      eval "$(zoxide init zsh)"
      eval "$(atuin init zsh)"
      eval "$(starship init zsh)"

      # Run anything
      justrun() {
        local cmd="$1"
        shift
        nix shell --impure "nixpkgs#$cmd" -c "$cmd" "$@"
      }

      addshell() {
        for pkg in "$@"; do
          if NIXPKGS_ALLOW_UNFREE=1 nix-shell -p $pkg; then
            echo "✅ Available: $pkg"
          else
            echo "❌ Failed: $pkg" >&2
          fi
        done
      }
    '';
  };

  environment.systemPackages = with pkgs; [
    # SysAdmin
    powertop # power management
    uutils-coreutils
    unixtools.whereis
    pciutils
    gnumake
    lsof
    usbutils
    lnav
    fastfetch
    pv
    jujutsu
    wget

    # TESTING: shells
    # nushell
    fish

    # zsh
    starship

    # Terminal
    ghostty
    warp-terminal
    # allacritty

    # AMD
    rocmPackages.rocm-smi

    # cli tools
    yt-dlp
    btop-rocm # better top with amd support
    libnotify # cli notifications
    jq # json parser
    lz4 # compression

    # Silly
    figlet # ascii art
    toilet # ascii art
    cowsay # ascii art
    lolcat # rainbow text
    sl # steam locomotive
    cmatrix # matrix effect
    fortune # random quotes

    # better cli
    atuin # fancy cli history
    pueue # task manager
    fzf # fuzzy finder
    ripgrep # better grep
    fd # better find
    bat # better cat
    eza # better ls
    dust # better du
    procs # better ps
    broot # better tree
    zoxide # better cd
    tealdeer # better tldr
    wl-clipboard # clipboard

    gping # ping with a graph
    gitui
    hyperfine # command-line benchmarking tool
    jless # json viewer

    # TESTING: rust cli tools
    xh # better curl
    zellij # better tmux
    yazi # better ranger
    helix # better vim
    bacon # better cargo
    cargo-info # better cargo info
    fselect # better find
    ncspot # better spotify
    rusty-man # better man
    # git-delta   # better git diff
    ripgrep-all # better ripgrep
    tokei # better wc
    wiki-tui # better wikipedia // wikiti is rust
    just # better make
    mask # better make
    mprocs # better docker-compose
    # present-term # better reveal.js
  ];
}
