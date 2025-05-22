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
}