{ pkgs, ... }:

{ 
  # Programs
  programs = {
    # firefox = {
    #   enable = true;
    # };

    adb.enable = true;
    direnv.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    starship.enable = true;
    neovim = {
      enable = true;
      defaultEsditor = true;
      vimAlias = true;
      viAlias = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };
}