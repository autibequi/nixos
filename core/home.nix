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

      programs.git = {
        enable = true;
        userName = "Pedro Correa";
        userEmail = "pedro@autibequi.com";
      };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.apple-cursor;
        name = "MacOS-White";
        size = 40;
      };

      home.file = {
        # avatar
        ".face".source = ../assets/avatar.png;

        # dotfiles
        ".config/ghosty/config".source = ../dotfiles/ghostty.conf;
        ".config/atuin/config.toml".source = ../dotfiles/atuin.conf;
        ".config/fastfetch/config.jsonc".source = ../dotfiles/fastfetch.jsonc;

        # Zed
        # ".config/zed" = {
        #   source = "~/projects/nixos/dotfiles/zed";
        #   recursive = true;
        # };

        # wallpapers
        ".wallpapers/the-death-of-socrates.jpg".source = ../assets/wallpapers/the-death-of-socrates.jpg;
        ".wallpapers/the-wild-hunt-of-odin.jpg".source = ../assets/wallpapers/the-wild-hunt-of-odin.jpg;
      };
    };
}
