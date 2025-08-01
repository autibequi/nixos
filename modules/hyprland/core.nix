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
        hyprspace
        hyprwinwrap
        hypr-dynamic-cursors
        hyprspace
        hyprsplit
        # hyprscrolling
        # hyprtrails
        # hyprfocus
      ])
      ++ [
        inputs.hyprtasking.packages.${pkgs.system}.hyprtasking
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

  # aparently i need gnome just to toggle my theme
  # But i dont need pp daemon. managed by battery.nix module
  services.xserver.desktopManager.gnome.enable = true;
  services.power-profiles-daemon.enable = false;

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
    anyrun
    walker
    onagre
    swww
    bluetuith
    ncpamixer
    tesseract
    satty

    glib
    gsettings-desktop-schemas
    dconf

    # Essential utilities only
    libnotify # Notification support
    pavucontrol # Audio control
    brightnessctl # Screen brightness
    playerctl # Media control

    nwg-displays # Display management
    hyprlock
    waybar
    anyrun
    cliphist # Clipboard history manager
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
      configFile = ./dotfiles/hypr/dunst.conf;
    };

    home.file = {
      # Hyperbasic
      ".config/hypr/hyprlock.conf".source = ./dotfiles/hypr/lock.conf;
      ".config/hypr/hyprshade.toml".source = ./dotfiles/hypr/shade.toml;
      ".config/hypr/hypridle.conf".source = ./dotfiles/hypr/idle.conf;
      ".config/hypr/hyprland.conf".source = ./dotfiles/hypr/land.conf;

      # Fuzzel
      ".config/fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel/fuzzel.ini;

      # Anyrun
      ".config/anyrun/config.ron".source = ./dotfiles/anyrun/config.ron;
      ".config/anyrun/plugins.ron".source = ./dotfiles/anyrun/plugins.ron;
      ".config/anyrun/style.css".source = ./dotfiles/anyrun/style.css;

      # Darkmode
      ".config/hypr/toggle-theme.sh".source = ./dotfiles/hypr/toggle-theme.sh;

      # Waybar
      ".config/waybar/config.jsonc".source = ./dotfiles/waybar/waybar.jsonc;
      ".config/waybar/style.css".source = ./dotfiles/waybar/waybar.css;
      ".config/waybar/restart.sh".source = ./dotfiles/waybar/restart.sh;

      # scripts
      ".config/waybar/tlp-status.sh".source = ./dotfiles/waybar/tlp-status.sh;
      ".config/waybar/tlp-toggle.sh".source = ./dotfiles/waybar/tlp-toggle.sh;
      ".config/hypr/escape-workspaces.sh".source = ./dotfiles/hypr/escape-workspaces.sh;
      ".config/hypr/switch-special-workspace.sh".source = ./dotfiles/hypr/switch-special-workspace.sh;

      # Shaders
      ".config/hypr/shaders".source = ./shaders;
      ".config/hypr/shaders".recursive = true;
    };
  };
}