{ ... }:
{
  home-manager.users."pedrinho" =
    { ... }:
    {
      gtk = {
        enable = true;
        iconTheme.name = "Papirus";
      };

      dconf = {
        enable = true;
        settings = {
          # Interface e Aparência
          "org/gnome/desktop/interface" = {
            cursor-size = 40;
            cursor-theme = "banana";
            enable-animations = false;
          };

          # Mouse e Periféricos
          "org/gnome/desktop/peripherals/mouse" = {
            natural-scroll = true;
          };

          # Mutter e Gerenciamento de Janelas
          "org/gnome/mutter" = {
            experimental-features = [
              "scale-monitor-framebuffer"
              "variable-refresh-rate"
            ];
          };

          "org/gnome/desktop/wm/preferences" = {
            focus-mode = "sloppy"; # sloppy (hover focus), smart (click focus), click, none
          };

          # Keybindings
          "org/gnome/desktop/wm/keybindings" = {
            # Workspace Management
            "switch-to-workspace-left" = [ "<Super>a" ];
            "switch-to-workspace-right" = [ "<Super>d" ];
            "move-to-workspace-left" = [ "<Super>q" ];
            "move-to-workspace-right" = [ "<Super>e" ];

            # Window Management
            "close" = [ "<Super>Escape" ];
            "maximize" = [ "<Super>tab" ];
            "minimize" = [ "<Super>s" ];
          };

          "org/gnome/shell/keybindings" = {
            "toggle-overview" = [ "<Super>z" ];
            "toggle-message-tray" = [ "<Super>x" ];
            "toggle-application-menu" = [ "<Super>c" ];
            "show-screenshot-ui" = [ "<Super>u" ];
          };

          # Custom Keybindings
          "org/gnome/settings-daemon/plugins/media-keys" = {
            custom-keybindings = [
              "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            ];
          };

          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            name = "Open Zed in NixOS Project";
            command = "sh -c 'cd ~/projects/nixos && zeditor .'";
            binding = "<Super>comma";
          };
        };
      };
    };
}
