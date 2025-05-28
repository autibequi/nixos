{ ... }:
{
  # avoid file colisions
  home-manager.backupFileExtension = "backup";

  # it's a me, pedrinho! o-ho!
  home-manager.users."pedrinho" =
    { pkgs, ... }:
    {
      home.stateVersion = "25.05";
      home.enableNixpkgsReleaseCheck = false;

      home.pointerCursor = {
        package = pkgs.banana-cursor;
        name = "Banana";
        size = 40;
      };

      home.file = {
        # avatar
        ".face".source = ../assets/avatar.png;

        # dotfiles
        ".config/ghosty/config".source = ../dotfiles/ghostty.conf;
        ".config/atuin/config.toml".source = ../dotfiles/atuin.conf;
        ".config/fastfetch/config.jsonc".source = ../dotfiles/fastfetch.jsonc;

        # Zed doesnt like it and throws ReadOnly issue
        # ".config/zed/keymap.json".source = ../dotfiles/zed/keymap.json;
        # ".config/zed/settings.json".source = ../dotfiles/zed/settings.json;

        # wallpapers
        ".wallpapers/the-death-of-socrates.jpg".source = ../assets/wallpapers/the-death-of-socrates.jpg;
        ".wallpapers/the-wild-hunt-of-odin.jpg".source = ../assets/wallpapers/the-wild-hunt-of-odin.jpg;
      };
    };
}
