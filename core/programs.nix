{ pkgs, ... }:

{
  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;
    starship.settings = {
    };

    firefox = {
      package = pkgs.firefox-beta-unwrapped;
      enable = true;
      languagePacks = [ "pt-BR" ];
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
    };

    steam = {
      enable = true;
      extest.enable = true;
      remotePlay.openFirewall = true;
    };
  };
}
