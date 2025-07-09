{ pkgs, ... }:

{
  # Hyprland - Window Manager focused on developer experience
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  # Power management daemon
  services.power-profiles-daemon.enable = true;

  # Audio support
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Essential packages only - avoid bloat
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
    # quickshell
    # qt6.qt5compat

    # Essential utilities only
    libnotify # Notification support
    pavucontrol # Audio control
    brightnessctl # Screen brightness
    playerctl # Media control

    nwg-displays # Display management

    anyrun
  ];

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal
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

      hyprshade
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };
  };

  # Hyprland config
  home-manager.users."pedrinho" = {
    # Dunst - Minimal notification setup
    services.dunst = {
      enable = true;
      configFile = ../dotfiles/hyprland/dunst.conf;
    };

    # Waybar - Focus on useful information only
    programs.waybar = {
      enable = true;
    };

    programs.hyprlock.enable = true;

    # Wofi - Fuzzy finder for applications (never search with eyes)
    programs.wofi = {
      enable = true;
      settings = {
        width = 600;
        height = 400;
        location = "center";
        show = "drun";
        prompt = "What the hell do you want...";
        filter_rate = 100;
        allow_markup = true;
        no_actions = true;
        halign = "fill";
        orientation = "vertical";
        content_halign = "fill";
        insensitive = true;
        allow_images = true;
        image_size = 40;
        gtk_dark = true;
      };
    };

    home.file = {
      ".config/hypr/hyprlock.conf".source = ../dotfiles/hypr/hyprlock.conf;
      ".config/hypr/hyprshade.toml".source = ../dotfiles/hypr/hyprshade.toml;
      ".config/hypr/hypridle.conf".source = ../dotfiles/hypr/hypridle.conf;
      ".config/waybar/config.jsonc".source = ../dotfiles/waybar/waybar.jsonc;
      ".config/waybar/style.css".source = ../dotfiles/waybar/waybar.css;
      ".config/fuzzel/fuzzel.ini".source = ../dotfiles/fuzzel/fuzzel.ini;
    };

    # Developer-focused scripts
    home.file.".config/hypr/refresh_de.sh" = {
      text = ''
        #!/bin/bash
        # Refresh developer tools quickly
        pkill waybar && waybar &
        notify-send "Dev tools refreshed"
      '';
      executable = true;
    };

    # Main Hyprland configuration with developer focus
    home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
    home.file.".config/hypr/hibernate.sh".source = ../dotfiles/hypr/hibernate.sh;
    home.file.".config/hypr/toggle-theme.sh".source = ../dotfiles/hypr/toggle-theme.sh;
  };
}
