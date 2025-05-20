{ pkgs, lib, ... }:
{
  home-manager.users."pedrinho" = { pkgs, lib, ... }:
  {
    gtk = {
      enable = true;
      theme.name = "Adwaita";
      iconTheme.name = "Papirus";
    };
    
    dconf = {
      enable = true;
      settings = {
        # Configurações dconf originais de de.nix
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };
        "org/gnome/mutter" = {
            experimental-features = [ "scale-monitor-framebuffer" "variable-refresh-rate" ];
        };
        "org/gnome/settings-daemon/plugins/sound" = {
          volume-step = 0.1;
        };
        "org/gnome/desktop/applications/terminal" = {
          exec = "${pkgs.ghostty}/bin/ghostty";
        };
        "org/gnome/desktop/interface" = {
            cursor-size = 40;
            cursor-theme = "banana";
        };
        "org/gnome/gnome-panel/layout" = { # Pode não ter efeito no Gnome Shell moderno
          bottom-panel = true;
        };
        "org/gnome/desktop/wm/preferences" = {
          focus-mode = "sloppy";
        };
        "org/gnome/desktop/interface" = {
          enable-animations = false;
        };

        # Custom terminal configurations
        # Configurações para terminal padrão
        "org/gnome/desktop/default-applications/terminal" = {
          exec = "${pkgs.ghostty}/bin/ghostty";
          exec-arg = "";
        };

        # Atalhos de teclado solicitados
        "org/gnome/desktop/wm/keybindings" = {
          "switch-to-workspace-left" = ["<Super>a"];
          "switch-to-workspace-right" = ["<Super>d"];
          "move-to-workspace-left" = ["<Super>q"];
          "move-to-workspace-right" = ["<Super>e"];
          "close" = ["<Super>Escape"];
          "maximize" = ["<Super>w"];
          "minimize" = ["<Super>s"];
        };
        "org/gnome/shell/keybindings" = {
          "toggle-overview" = ["<Super>z"];
          "toggle-message-tray" = ["<Super>x"];
          "toggle-application-menu" = ["<Super>c"];
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          "play" = ["<Super>space"];
          "next" = ["<Super>Right"];
          "previous" = ["<Super>Left"];
        };
        # Other apps
        # Vitals
        "org/gnome/shell/extensions/vitals" = {
          hot-sensors = ["_memory_usage_" "_processor_usage_" "_battery_rate_" "_battery_time_left_" "_temperature_acpi_thermal zone_"];
        };
      };
    };
  };
} 