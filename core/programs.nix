{ pkgs, ... }:

{ 
  # Programs
  programs = {
    # firefox = {
    #   enable = true;
    # };

    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

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
        man = "tldr";
        f = "fzf";
        ff = "fastfetch";
        clip = "wl-copy";
      };

      # Init some of those alias
      shellInit = ''
        eval "$(zoxide init zsh)"
        eval "$(atuin init zsh)"
        eval "$(starship init zsh)"
      '';
    };
    
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
    };
    
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  }; 
}