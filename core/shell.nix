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
      "history"
      "history-substring-search"
      "sudo"
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
    };
  };



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
    zoxide      # better cd
    tealdeer    # better tldr
    wl-clipboard # clipboard

    # shells
    nushell
    starship
    fish
    ghostty # terminals
  ];
}