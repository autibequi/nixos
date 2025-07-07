{ ... }:
{
  imports = [
    ./packages.nix
    ./extensions.nix
  ];

  # Will break next release
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Next Release
  # services = {
  #   desktopManager.gnome.enable = true;
  #   displayManager.gdm = {
  #     enable = true;
  #     wayland = true;
  #   };
  # };

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
            cursor-theme = "MacOs-White";
            enable-animations = false;
          };

          # Mouse e Periféricos
          "org/gnome/desktop/peripherals/mouse" = {
            natural-scroll = true;
          };

          "org/gnome/mutter" = {
            experimental-features = [
              "scale-monitor-framebuffer"
              "variable-refresh-rate"
            ];
          };

          "org/gnome/desktop/wm/preferences" = {
            focus-mode = "sloppy"; # sloppy (hover focus), smart (click focus), click, none
          };

          # Window Managment Keybindings
          "org/gnome/desktop/wm/keybindings" = {
            # Workspace Management
            "switch-to-workspace-left" = [ "<Super>a" ];
            "switch-to-workspace-right" = [ "<Super>d" ];
            "move-to-workspace-left" = [ "<Super>q" ];
            "move-to-workspace-right" = [ "<Super>e" ];

            # Window Management
            "close" = [ "<Super>Escape" ];
            "maximize" = [ "<Super>w" ];
            "minimize" = [ "<Super>s" ];
          };

          # Shell Keybindings
          "org/gnome/shell/keybindings" = {
            "toggle-overview" = [ "<Super>z" ];
            "toggle-message-tray" = [ "<Super>x" ];
            "toggle-application-menu" = [ "<Super>c" ];
            "show-screenshot-ui" = [ "<Super>u" ];
          };

          # Custom Keybinding for Zed Editor
          "org/gnome/settings-daemon/plugins/media-keys" = {
            custom-keybindings = [
              "/org/gnome/settings-daemon/plugins/media-keys/custom0"
            ];
          };

          "org/gnome/settings-daemon/plugins/media-keys/custom0" = {
            binding = "<Super>comma";
            command = "sh -c 'cd ~/projects/nixos && zeditor .'";
            name = "Open Zed in NixOS Project";
          };
        };
      };
    };
}
