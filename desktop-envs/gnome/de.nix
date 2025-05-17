{ config, pkgs, lib, ... } :

{
  imports = [
    ../aesthetics.nix
  ];

  # Desktop Environment
  services = {

    xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };

      desktopManager.gnome.enable = true;
      xkb = {
        layout = "us";
        variant = "alt-intl";
      };
    };

    gnome = {
      gnome-browser-connector.enable = true;
      gnome-remote-desktop.enable = false;
    };
  };

  environment.systemPackages = with pkgs; [
    # Gnome Stuff
    desktop-file-utils
    gnome-extension-manager

    # Utils
    pkgs.gnome-tweaks

    # Icon Theme
    pkgs.adwaita-icon-theme

    # Extensions
    # Productivity Extensions
    gnomeExtensions.caffeine
    gnomeExtensions.pano
    gnomeExtensions.gsconnect
    gnomeExtensions.auto-power-profile
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.quick-settings-audio-panel

    # Battery and Power Extensions
    gnomeExtensions.battery-time
    gnomeExtensions.upower-battery

    # Window Management Extensions
    gnomeExtensions.tiling-shell
    gnomeExtensions.window-gestures
    gnomeExtensions.wtmb-window-thumbnails

    # Visual and UI Enhancements
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.mouse-tail
    gnomeExtensions.wiggle
    gnomeExtensions.hide-cursor
    gnomeExtensions.emoji-copy
    gnomeExtensions.open-bar

    # System and Utility Extensions
    gnomeExtensions.vitals
    gnomeExtensions.media-controls
    gnomeExtensions.appindicator
    gnomeExtensions.restart-to
    gnomeExtensions.fuzzy-app-search
    gnomeExtensions.gnome-40-ui-improvements
  ];

  # Gnome Debloat
  # Exclude Core Apps From Being Installed.
  environment.gnome.excludePackages = with pkgs.gnome; [
    pkgs.epiphany
    pkgs.gedit
    pkgs.totem
    pkgs.yelp
    pkgs.geary
    pkgs.gnome-calendar
    pkgs.gnome-contacts
    pkgs.gnome-maps
    pkgs.gnome-music
    pkgs.gnome-photos
    pkgs.gnome-tour
    pkgs.evince
    pkgs.gnome-weather
    pkgs.gnome-clocks
    pkgs.gnome-characters
    pkgs.gnome-sound-recorder
    pkgs.gnome-logs
    pkgs.gnome-usage
    pkgs.simple-scan
    pkgs.gnome-connections
    pkgs.gnome-text-editor
    pkgs.gnome-font-viewer
  ];
  

  # Home Manager Gnome Modifications
  home-manager.users."pedrinho" = { lib, ... }: {
    # Gnome Basic Crap
    dconf = {
      enable = true;
      settings = {
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
        "org/gnome/gnome-panel/layout" = {
          bottom-panel = true;
        };
      };

    };

  # Set glitch effect to Burn My Windows
    home.file."~/.config/gnome-shell/extensions/burn-my-windows/profiles/1747253129691946.conf".source = ../desktop-envs/gnome/extensions-configs/burn-my-windows.conf;
  };

  # Restart Extensions 'cos gnome stuff 💅
  powerManagement.resumeCommands = 
  ''
    gsettings set org.gnome.shell disable-user-extensions true
    gsettings set org.gnome.shell disable-user-extensions false
  '';
}
