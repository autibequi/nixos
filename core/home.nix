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
        package = pkgs.banana-cursor;
        name = "Banana";
        size = 80;
      };

      home.file = {
        # avatar
        ".face".source = ../assets/avatar.png;

        # wallpapers
        ".wallpapers/light.jpg".source = ../assets/wallpapers/the-death-of-socrates.jpg;
        ".wallpapers/dark.jpg".source = ../assets/wallpapers/the-wild-hunt-of-odin.jpg;
      };
    };
}
