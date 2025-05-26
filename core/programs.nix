{ pkgs, ... }:

{
  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;
    starship.settings = {
      format = ''
        [┌───────────────────>](bold green)
        [│](bold green)$directory$rust$package
        [└─>](bold green) '';
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