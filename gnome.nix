{ config, pkgs, lib, ... } :

{
  # Desktop Environment
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  services.gnome = {
    gnome-browser-connector.enable = true;
    gnome-remote-desktop.enable = false;
  };

  environment.systemPackages = with pkgs; [
    # Gnome Stuff
    desktop-file-utils
    gnome-extension-manager
    ghostty # due to gnome-terminal being removed

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
    pkgs.gnome-software
    pkgs.gnome-connections
    pkgs.gnome-text-editor
    pkgs.gnome-font-viewer
  ];
  
  # nixpkgs.config.allowAliases = false;
  # nixpkgs.overlays = [
  #   # GNOME 46: triple-buffering-v4-46
  #   (final: prev: {
  #     mutter = prev.mutter.overrideAttrs (old: {
  #       src = pkgs.fetchFromGitLab  {
  #         domain = "gitlab.gnome.org";
  #         owner = "vanvugt";
  #         repo = "mutter";
  #         rev = "triple-buffering-v4-46";
  #         hash = "sha256-C2VfW3ThPEZ37YkX7ejlyumLnWa9oij333d5c4yfZxc=";
  #       };
  #     });
  #   })
  # ];

    # Home Manager
  home-manager.users."pedrinho" = { lib, ... }: {
    # Gnome Basic Crap
    dconf.settings = {
      "org/gnome/desktop/peripherals/mouse" = { natural-scroll = true; };
      # "org/gnome/desktop/wm/keybindings" = {
      #   switch-to-workspace-left = ["<Super>a"];
      #   switch-to-workspace-right = ["<Super>d"];
      #   close = ["<Primary><Shift>q"];
      # };
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer"];
      };
      "org/gnome/settings-daemon/plugins/sound" = {
        volume-step = 1;
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
