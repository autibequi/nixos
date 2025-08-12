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

      home.file = {
        # avatar
        ".face".source = ../../assets/avatar.png;

        # wallpapers
        ".wallpapers/light.jpg".source = ../../assets/wallpapers/the-death-of-socrates.jpg;
        ".wallpapers/dark.jpg".source = ../../assets/wallpapers/the-wild-hunt-of-odin.jpg;

        # Gamescope configuration
        ".config/gamescope.sh".source = ../../scripts/gamescope.sh;
      };

      xdg.desktopEntries."gemini-app" = {
        name = "Gemini (App)";
        comment = "Google Gemini como aplicativo web";
        exec = "${pkgs.google-chrome}/bin/chromium --app=https://gemini.google.com";
        icon = "google-chrome";
        type = "Application";
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      xdg.desktopEntries."calendar-app" = {
        name = "Google Calendar (App)";
        comment = "Google Calendar como aplicativo web";
        exec = "${pkgs.google-chrome}/bin/chromium --app=https://calendar.google.com";
        icon = "google-chrome";
        type = "Application";
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      xdg.desktopEntries."chat-app" = {
        name = "Google Chat (App)";
        comment = "Google Chat como aplicativo web";
        exec = "${pkgs.google-chrome}/bin/chromium --app=https://chat.google.com";
        icon = "google-chrome";
        type = "Application";
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      xdg.desktopEntries."gmail-app" = {
        name = "Gmail (App)";
        comment = "Gmail como aplicativo web";
        exec = "${pkgs.google-chrome}/bin/chromium --app=https://mail.google.com";
        icon = "google-chrome";
        type = "Application";
        categories = [
          "Network"
          "Email"
          "WebBrowser"
        ];
      };

      xdg.desktopEntries."youtube-app" = {
        name = "YouTube (App)";
        comment = "YouTube como aplicativo web";
        exec = "${pkgs.chromium}/bin/chromium --app=https://www.youtube.com";
        icon = "youtube";
        type = "Application";
        categories = [
          "AudioVideo"
          "Video"
          "WebBrowser"
        ];
      };

      xdg.desktopEntries."youtube-music-app" = {
        name = "YouTube Music (App)";
        comment = "YouTube Music como aplicativo web";
        exec = "${pkgs.chromium}/bin/chromium --app=https://music.youtube.com";
        icon = "youtube-music";
        type = "Application";
        categories = [
          "AudioVideo"
          "Audio"
          "WebBrowser"
        ];
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
