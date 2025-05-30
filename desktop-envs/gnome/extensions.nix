{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Extensions
    # Productivity Extensions
    gnomeExtensions.caffeine
    gnomeExtensions.pano
    gnomeExtensions.gsconnect
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.quick-settings-audio-panel
    gnomeExtensions.auto-power-profile
    gnomeExtensions.battery-health-charging
    gnomeExtensions.grand-theft-focus

    # Window Management Extensions
    gnomeExtensions.tiling-shell
    gnomeExtensions.window-gestures
    gnomeExtensions.wtmb-window-thumbnails

    # Visual and UI Enhancements
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.hide-cursor
    gnomeExtensions.emoji-copy
    gnomeExtensions.open-bar
    gnomeExtensions.window-desaturation

    # System and Utility Extensions
    gnomeExtensions.vitals
    gnomeExtensions.media-controls
    gnomeExtensions.appindicator
    gnomeExtensions.fuzzy-app-search
    gnomeExtensions.gnome-40-ui-improvements
    gnomeExtensions.advanced-alttab-window-switcher
    gnomeExtensions.custom-command-toggle
    gnomeExtensions.upower-battery

    # super cool but nukes battery life due to GPU usage on idle
    # gnomeExtensions.mouse-tail
    # gnomeExtensions.wiggle
  ];

  # Config Moving
  home-manager.users."pedrinho" =
    { ... }:
    {
      home.file."~/.config/gnome-shell/extensions/burn-my-windows/profiles/pedrinho.profile.conf".source =
        ./extensions-configs/burn-my-windows.conf;
      home.file."~/toggle.ini".source = ./extensions-configs/custom-toggle.conf;

      dconf.settings = {
        # Extensões
        # Vitals
        "org/gnome/shell/extensions/vitals" = {
          hot-sensors = [
            "_processor_usage_"
            "_memory_usage_"
            "_battery_rate_"
            "_battery_time_left_"
            "_temperature_acpi_thermal zone_"
          ];
        };

        # Caffeine
        "org/gnome/shell/extensions/caffeine" = {
          countdown-timer = 28800;
          duration-timer-list = [
            1800
            3600
            28800
          ];
          use-custom-duration = true;
          user-enabled = true;
          enable-fullscreen = true;
          indicator-position = 0;
          show-indicator = "only-active";
          screen-blank = "never";
        };

        # Pano
        "org/gnome/shell/extensions/pano" = {
          history-length = 50;
          item-size = 200;
          send-notification-on-copy = false;
          session-only-mode = true;
          sync-primary = false;
        };

        # Auto Power Profile
        "org/gnome/shell/extensions/auto-power-profile" = {
          bat = "power-saver";
          ac = "power-saver";
          threshold = 100;
        };

        # Tilingshell
        "org/gnome/shell/extensions/tilingshell" = {
          inner-gaps = 4;
          outer-gaps = 4;
          layouts-json = ''[{"id":"5659034","tiles":[{"x":0,"y":0,"width":0.6496478873239436,"height":1,"groups":[1]},{"x":0.6496478873239436,"y":0,"width":0.35035211267605637,"height":1,"groups":[1]}]}]'';
          move-window-down = [ "<Shift><Super>s" ];
          move-window-left = [ "<Shift><Super>a" ];
          move-window-right = [ "<Shift><Super>d" ];
          move-window-up = [ "<Shift><Super>w" ];
          span-multiple-tiles-activation-key = [ "0" ];
          span-window-all-tiles = [ "<Super>Tab" ];
          tile-preview-animation-time = 50;
          tiling-system-activation-key = [ "2" ];
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
          active-profile = "/home/pedrinho/.config/burn-my-windows/profiles/pedrinho.profile.conf";
          preview-effect = "";
        };

        # Media Controls
        "org/gnome/shell/extensions/media-controls" = {
          colored-player-icon = false;
          extension-position = "Left";
          hide-media-notification = true;
          label-width = 500;
          labels-order = [
            "TITLE"
            ":"
            " by "
            ":"
            "ARTIST"
          ];
          scroll-labels = true;
          show-control-icons = false;
        };

        # Night Theme Switcher
        "org/gnome/shell/extensions/night-theme-switcher" = {
          # Wallpaper configuration
          wallpaper-light = "/home/pedrinho/.wallpapers/the-death-of-socrates.jpg";
          wallpaper-dark = "/home/pedrinho/.wallpapers/the-wild-hunt-of-odin.jpg";

          # Theme switching settings
          enable = true;
          time-source = "location";
          manual-time-source = false;
          ondemand-button = true;

          # Automatic switching based on sunset/sunrise
          auto-enable = true;
          schedule = true;
        };

        # Advanced Alt Tab Window Switcher
        "org/gnome/shell/extensions/advanced-alt-tab-window-switcher" = {
          alt-tab-mode = "window";
        };
      };
    };
}
