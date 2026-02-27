{ pkgs, pkgs-unstable, ... }:

let
  sharedAliases = {
    history = "atuin";
    tasks = "pueue";
    grep = "rg";
    findf = "fd";
    cat = "bat";
    ls = "lsd -la";
    du = "dust";
    ps = "procs";
    tree = "broot";
    f = "fzf --wrap";
    clip = "wl-copy";
    clipb = "wl-paste";
    zed = "zeditor";
    stow = "stow --target=$HOME";
    dotfiles = "stow --target=$HOME --dir=$HOME/projects/nixos stow";
    please = "sudo !!";
    vim = "hx";
    vi = "hx";
    wiki = "wikiti";
  };
in
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

    shellAliases = sharedAliases;

    shellInit = ''
      if [ "$TERM" != "dumb" ]; then
        eval "$(starship init zsh)"
        eval "$(zoxide init zsh)"
        eval "$(atuin init zsh)"

        source ~/secrets.sh
        source ~/.config/hypr/hyprutils.sh
        source ~/.config/zsh/functions.sh
      fi
    '';
  };

  programs.fish = {
    enable = true;
    shellAliases = sharedAliases;

    shellInit = ''
      if test "$TERM" != "dumb"
        starship init fish | source
        zoxide init fish | source
        atuin init fish | source
      end
    '';
  };

  environment.systemPackages = with pkgs; [
    # basic (why i had to install those)
    # uutils-coreutils # broken
    unixtools.whereis
    pciutils
    gnumake
    lsof
    usbutils
    wget
    git
    busybox

    # Utils
    # ----------------------
    lnav
    fastfetch
    pv
    clippy
    starship # zsh kit
    rocmPackages.rocm-smi # amd basics for btop

    # Coding
    # ---------------
    # Nix formating
    nil
    nixd
    nixfmt-rfc-style

    # Markdown LSP
    markdown-oxide

    # Rust
    cargo
    rustc
    rustup
    rust-analyzer
    rustfmt

    # Misc
    jujutsu # git based replacement (confusing)

    # cli tools
    btop-rocm # better top with amd support
    libnotify # cli notifications
    jq # json parser

    # Silly
    figlet # ascii art
    toilet # ascii art
    cowsay # ascii art
    lolcat # rainbow text
    sl # steam locomotive
    cmatrix # matrix effect
    fortune # random quotes

    # snippet manager
    pet

    # better cli
    atuin # fancy cli history
    pueue # task manager
    fzf # fuzzy finder
    ripgrep # better grep
    fd # better find
    bat # better cat
    lsd # better ls
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
    #
    #

    isd

    # node ieks
    pnpm
    nodejs

    # Media
    mpv
    yt-dlp

    # org
    # taskwarrior3
    # taskwarrior-tui
  ];
}
