{ pkgs, ... }:

{
  # Hyprland
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  # Environment Variables
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

  # Audio support
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Add essential packages for the Hyprland experience
  environment.systemPackages = with pkgs; [
    # Core Hyprland tools
    waybar
    hyprpaper
    wofi
    alacritty
    kdePackages.dolphin
    dunst
    swaylock-effects # Better than regular swaylock
    grim
    slurp
    wl-clipboard

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome

    # Utilities
    libnotify
    pavucontrol
    networkmanagerapplet
    brightnessctl
    playerctl
    imagemagick

    # Icon themes
    papirus-icon-theme
    adwaita-icon-theme
  ];

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      font-awesome
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };
  };

  # Hyprland config
  home-manager.users."pedrinho" = {
    # Dunst - Notification Daemon
    services.dunst.configFile = (builtins.path { path = ../../dotfiles/hyprland/dunst.conf; });

    # Waybar configuration
    programs.waybar = {
      enable = true;
      settings = builtins.fromJSON (builtins.readFile (builtins.path { path = ../../dotfiles/hyprland/waybar.conf; }));
      style = builtins.readFile (builtins.path { path = ../../dotfiles/hyprland/waybar.css; });
    };

    # Create a simple solid color wallpaper script
    home.file.".config/hypr/set_wallpaper.sh" = {
      source = (builtins.path { path = ../../dotfiles/hyprland/set_wallpaper.sh; });
      executable = true;
    };

    # Create debug startup script
    home.file.".config/hypr/debug_start.sh" = {
      source = (builtins.path { path = ../../dotfiles/hyprland/debug_start.sh; });
      executable = true;
    };

    # Hyprpaper configuration for wallpaper
    home.file.".config/hypr/hyprpaper.conf" = {
      source = (builtins.path { path = ../../dotfiles/hyprland/hyprpaper.conf; });
    };

    # Main Hyprland configuration
    home.file.".config/hypr/hyprland.conf" = {
      source = (builtins.path { path = ../../dotfiles/hyprland/hyprland.conf; });
    };
  };
}