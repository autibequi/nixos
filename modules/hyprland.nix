{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    # Core Hyprland tools for navigation and productivity
    waybar # Status bar with useful info
    wofi # App launcher (fuzzy finding)
    alacritty # Terminal
    dunst # Notifications
    grim # Screenshots
    swappy # Screen editing
    slurp # Screen selection
    wl-clipboard # Clipboard management
    hypridle
    hyprshade
    fuzzel
    walker
    onagre
    swww
    bluetuith
    ncpamixer
    tesseract
    satty

    glib

    # quickshell
    # qt6.qt5compat

    # Essential utilities only
    libnotify # Notification support
    pavucontrol # Audio control
    brightnessctl # Screen brightness
    playerctl # Media control

    nwg-displays # Display management
    hyprlock
    waybar
    anyrun
  ];

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  # Hyprland config
  home-manager.users."pedrinho" = {
    # Dunst - Minimal notification setup
    services.dunst = {
      enable = true;
      configFile = ../dotfiles/hyprland/dunst.conf;
    };

    home.file = {
      # Hyperbasic
      ".config/hypr/hyprlock.conf".source = ../dotfiles/hypr/hyprlock.conf;
      ".config/hypr/hyprshade.toml".source = ../dotfiles/hypr/hyprshade.toml;
      ".config/hypr/hypridle.conf".source = ../dotfiles/hypr/hypridle.conf;
      ".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;

      # Fuzzel
      ".config/fuzzel/fuzzel.ini".source = ../dotfiles/fuzzel/fuzzel.ini;

      # Darkmode
      ".config/hypr/toggle-theme.sh".source = ../dotfiles/hypr/toggle-theme.sh;

      # Waybar
      ".config/waybar/config.jsonc".source = ../dotfiles/waybar/waybar.jsonc;
      ".config/waybar/style.css".source = ../dotfiles/waybar/waybar.css;
      ".config/waybar/restart.sh".source = ../dotfiles/waybar/restart.sh;
    };
  };
}
