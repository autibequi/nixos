{ ... }:

{
  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;
    starship.settings = {
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
