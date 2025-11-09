{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths =
      (with pkgs.hyprlandPlugins; [
        hyprexpo
        hyprwinwrap
        hypr-dynamic-cursors
        hyprsplit

        # hyprspace
        # hyprscrolling
        # hyprtrails
        # hyprfocus
      ])
      ++ [
        # inputs.hyprtasking.packages.${pkgs.system}.hyprtasking
      ];
  };
in
{
  services.hypridle.enable = true;

  environment.sessionVariables = {
    HYPR_PLUGIN_DIR = hypr-plugin-dir;
    ANYRUN_PLUGIN_DIR = "${pkgs.anyrun}/lib";
  };

  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    hyprpicker
    hyprpolkitagent

    # Core Hyprland tools for navigation and productivity
    waybar # Status bar with useful info
    wofi # App launcher (fuzzy finding)
    alacritty # Terminal
    # dunst # Notifications
    swaynotificationcenter # Notifications
    grim # Screenshots
    swappy # Screen editing
    slurp # Screen selection
    wl-clipboard # Clipboard management
    hypridle
    hyprshade
    fuzzel
    anyrun
    walker
    onagre
    swww
    mpvpaper
    waytrogen
    bluetuith
    ncpamixer
    tesseract
    satty

    # hyprcursor
    rose-pine-hyprcursor

    # Dark/Light Theme Toggle via gnome crap
    glib
    gsettings-desktop-schemas
    dconf
    
    # gtk confy
    nautilus

    # Essential utilities only
    libnotify # Notification support
    pavucontrol # Audio control
    brightnessctl # Screen brightness
    playerctl # Media control

    nwg-displays # Display management
    hyprlock
    cliphist # Clipboard history manager
  ];
}

