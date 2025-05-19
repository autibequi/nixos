{ config, pkgs, home-manager, ... }:
{
  # avoid file colisions
  home-manager.backupFileExtension = "hm-backup";

  # it's a me, pedrinho! o-ho!
  home-manager.users."pedrinho" = { lib, ... }: {
    home.stateVersion = "25.05";
    home.enableNixpkgsReleaseCheck = false;

    # Banana cursor theme
    home.pointerCursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = 40;
    };

    home.file = {
      # avatar
      ".face".source = ../assets/avatar.png;

      # dotfiles
      ".config/ghosty/config".source = ../dotfiles/ghostty.conf;
      ".config/atuin/config.toml".source = ../dotfiles/atuin.conf;
      ".config/fastfetch/config.jsonc".source = ../dotfiles/fastfetch_small.jsonc;
    };
  };
}