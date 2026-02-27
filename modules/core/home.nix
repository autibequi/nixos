{ ... }:
{
  # avoid file colisions
  home-manager.backupFileExtension = "backup";

  # it's a me, pedrinho! o-ho!
  home-manager.users."pedrinho" =
    { ... }:
    {
      home.stateVersion = "25.11";
      home.enableNixpkgsReleaseCheck = false;

      programs.git = {
        enable = true;
        settings.user = {
          name = "Pedro Correa";
          email = "pedro@autibequi.com";
        };
      };

      # Corrige erro de caractere reservado no campo Exec (desktop spec)
      xdg.desktopEntries."obsidian-work" = {
        name = "Obsidian (Work)";
        comment = "Obsidian como aplicativo web";
        exec = "xdg-open \"obsidian://open?vault=Work\"";
        icon = "obsidian";
        type = "Application";
        categories = [
          "Office"
          "TextEditor"
        ];
      };

      xdg.desktopEntries."obsidian-personal" = {
        name = "Journal (Obsidian)";
        comment = "Obsidian como aplicativo web";
        exec = "xdg-open \"obsidian://open?vault=books\"";
        icon = "obsidian";
        type = "Application";
        categories = [
          "Office"
          "TextEditor"
        ];
      };
    };
}
