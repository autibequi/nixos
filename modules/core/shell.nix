{ pkgs, unstable, ... }:

let
  sharedAliases = {
    history = "atuin";
    grep = "rg";
    findf = "fd";
    cat = "bat";
    ls = "lsd -la";
    f = "fzf --wrap";
    clip = "wl-copy";
    clipb = "wl-paste";
    stow = "stow --target=$HOME";
    dotfiles = "stow --target=$HOME --dir=$HOME/nixos stow";
    please = "sudo !!";
    wiki = "wikiti";
    du = "dust";
    ps = "procs";
    sed = "sd";
    jq = "jaq";
  };
in
{
  # Claude Code config dir — fora do ~/.claude padrão
  environment.sessionVariables = {
    CLAUDE_CONFIG_DIR = "$HOME/.local/share/claude-code";
  };
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
      source ~/.config/zsh/init.sh
    '';
  };

  # dash como /bin/sh (4x mais rápido que bash para scripts)
  environment.binsh = "${pkgs.dash}/bin/dash";

  environment.systemPackages = with pkgs; [
    dash
    bash
    # basic (why i had to install those)
    uutils-coreutils # rust coreutils
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
    starship # zsh kit
    rocmPackages.rocm-smi # amd basics for btop

    # Coding
    # ---------------
    # Nix
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

    # cli tools
    btop-rocm # better top with amd support
    jaq # better jq (rust)

    # snippet manager
    pet

    # better cli
    atuin # fancy cli history
    fzf # fuzzy finder
    ripgrep # better grep
    fd # better find
    bat # better cat
    lsd # better ls
    zoxide # better cd
    tealdeer # better tldr

    gping # ping with a graph
    gitui
    hyperfine # benchmarking
    jless # json viewer

    # rust cli tools
    xh # better curl
    zellij # better tmux
    helix # better vim
    bacon # better cargo
    cargo-info # better cargo info
    ncspot # spotify TUI
    tokei # code stats
    wiki-tui # wikipedia TUI
    just # better make
    dust # better du
    procs # better ps
    sd # better sed
    bandwhich # network monitor per process

    isd

    # node
    pnpm
    nodejs

    # Media
    yt-dlp
  ];
}
