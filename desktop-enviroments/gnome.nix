{ config, pkgs, lib, ... } :

{
  # Desktop Environment
  services = {

    xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      # displayManager.sddm.enable = true;
      # displayManager.lightdm = {
      #   enable = true;
      #   greeters.gtk.enable = true;
      # };

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
    ghostty # due to gnome-terminal being removed

    # Icon Theme
    pkgs.adwaita-icon-theme
    pkgs.gnome-tweaks

    # Extensions
    gnomeExtensions.just-perfection
    gnomeExtensions.caffeine
    gnomeExtensions.pano
    gnomeExtensions.appindicator
    gnomeExtensions.gsconnect
    gnomeExtensions.auto-power-profile        
    gnomeExtensions.tiling-assistant        
    gnomeExtensions.battery-health-charging
    gnomeExtensions.vertical-workspaces
    gnomeExtensions.tiling-shell
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.battery-time
    gnomeExtensions.upower-battery
    gnomeExtensions.bluetooth-battery
    gnomeExtensions.quick-settings-audio-panel
    gnomeExtensions.wtmb-window-thumbnails
    gnomeExtensions.battery-time
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
    pkgs.gnome-console
    pkgs.gnome-connections
    pkgs.gnome-text-editor
    pkgs.gnome-font-viewer
  ];
  

  # programs.dconf.enable = true;
  
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
      };
    };

    home.file = {
      # Gnome Cecidilha Fix
      ".XCompose".text = ''
        # I shouldn't need to do this, but I do...
        # https://github.com/NixOS/nixpkgs/issues/239415
        include "%L"

        <dead_acute> <C> : "Ç"
        <dead_acute> <c> : "ç"
      '';
    };
  };
}
