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
          experimental-features = [ "scale-monitor-framebuffer" "variable-refresh-rate" ];
        };

        "org/gnome/desktop/wm/preferences" = {
          focus-mode = "sloppy"; # sloppy (hover focus), smart (click focus), click, none
        };

        # Keybindings
        "org/gnome/desktop/wm/keybindings" = {
          # Workspace Management
          "switch-to-workspace-left" = ["<Super>a"];
          "switch-to-workspace-right" = ["<Super>d"];
          "move-to-workspace-left" = ["<Super>q"];
          "move-to-workspace-right" = ["<Super>e"];

          # Window Management
          "close" = ["<Super>Escape"];
          "maximize" = ["<Super>w"];
          "minimize" = ["<Super>s"];
        };

        "org/gnome/shell/keybindings" = {
          "toggle-overview" = ["<Super>z"];
          "toggle-message-tray" = ["<Super>x"];
          "toggle-application-menu" = ["<Super>c"];
        };

        # Extensões
        # Vitals
        "org/gnome/shell/extensions/vitals" = {
          hot-sensors = ["_memory_usage_" "_processor_usage_" "_battery_rate_" "_battery_time_left_" "_temperature_acpi_thermal zone_"];
        };

        # Caffeine
        "org/gnome/shell/extensions/caffeine" = {
          countdown-timer = 28800;
          duration-timer-list = [1800 3600 28800];
          use-custom-duration = true;
          user-enabled = true;
        };

        # Pano
        "org/gnome/shell/extensions/pano" = {
          history-length = 50;
          item-size = 200;
          send-notification-on-copy = false;
          session-only-mode = true;
          sync-primary = false;
        };

        # Tilingshell
        "org/gnome/shell/extensions/tilingshell" = {
          inner-gaps = 4;
          outer-gaps = 4;
          layouts-json = ''[{"id":"5659034","tiles":[{"x":0,"y":0,"width":0.6496478873239436,"height":1,"groups":[1]},{"x":0.6496478873239436,"y":0,"width":0.35035211267605637,"height":1,"groups":[1]}]}]'';
          move-window-down = ["<Shift><Super>s"];
          move-window-left = ["<Shift><Super>a"];
          move-window-right = ["<Shift><Super>d"];
          move-window-up = ["<Shift><Super>w"];
          span-multiple-tiles-activation-key = ["0"];
          span-window-all-tiles = ["<Super>Tab"];
          tile-preview-animation-time = 50;
          tiling-system-activation-key = ["2"];
          top-edge-maximize = true;
        };

        # Window Gestures
        "org/gnome/shell/extensions/windowgestures" = {
          edge-size = 96;
          fn-fullscreen = false;
          fn-maximized-snap = false;
          fn-move = false;
          fn-move-snap = false;
          fn-resize = false;
          swipe3-down = 0;
          swipe3-downup = 0;
          swipe3-left = 4;
          swipe4-left = 9;
          swipe4-right = 8;
          swipe4-updown = 1;
          taphold-move = true;
          three-finger = true;
          top-edge-size = 96;
          use-active-window = false;
        };

        # Burn My Windows
        "org/gnome/shell/extensions/burn-my-windows" = {
          active-profile="/home/pedrinho/.config/burn-my-windows/profiles/pedrinho.profile.conf";
          preview-effect="";
        };

        # Media Controls
        "org/gnome/shell/extensions/media-controls" = {
          colored-player-icon=false;
          extension-position="Left";
          hide-media-notification=true;
          label-width=500;
          labels-order = [ "TITLE" ":" " by " ":" "ARTIST" ];
          scroll-labels=true;
          show-control-icons=false;
        };

        # Advanced Alt Tab Window Switcher
        "org/gnome/shell/extensions/advanced-alt-tab-window-switcher" = {
          alt-tab-mode = "window";
        };
      };
    };
  };
}