{ pkgs, ... }:

{
  # Hyprland - Window Manager focused on developer experience
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  # Environment Variables - Keep defaults where possible
  environment.sessionVariables = {
    # Only essential variables for Hyprland
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
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

  # Essential packages only - avoid bloat
  environment.systemPackages = with pkgs; [
    # Core Hyprland tools for navigation and productivity
    waybar # Status bar with useful info
    wofi # App launcher (fuzzy finding)
    alacritty # Terminal
    dunst # Notifications
    grim # Screenshots
    slurp # Screen selection
    wl-clipboard # Clipboard management
    swaylock-effects # Screen lock

    # Essential utilities only
    libnotify # Notification support
    pavucontrol # Audio control
    brightnessctl # Screen brightness
    playerctl # Media control
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
    # Dunst - Minimal notification setup
    services.dunst = {
      enable = true;
      configFile = ../dotfiles/hyprland/dunst.conf;
    };

    # Waybar - Focus on useful information only
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;
          modules-left = [
            "hyprland/workspaces"
            "hyprland/window"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "pulseaudio"
            "network"
            "battery"
            "cpu"
            "memory"
            "tray"
          ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "1" = "🌐";
              "2" = "💬";
              "3" = "🧪";
              "4" = "💻";
              "5" = "🤖";
              "6" = "🎨";
              urgent = "❗";
              focused = "●";
              default = "○";
            };
          };

          "hyprland/window" = {
            format = "{title}";
            max-length = 50;
            separate-outputs = true;
          };

          clock = {
            format = "{:%d %H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d}";
          };

          cpu = {
            format = "CPU {usage}%";
            tooltip = false;
            interval = 10;
          };

          memory = {
            format = "RAM {used:0.1f}G";
            tooltip = false;
            interval = 10;
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ⚡";
            format-plugged = "{capacity}% 🔌";
            format-alt = "{time} {icon}";
            format-icons = [
              "🪫"
              "🔋"
              "🔋"
              "🔋"
              "🔋"
            ];
          };

          network = {
            format-wifi = "{essid} 📶";
            format-ethernet = "ETH 🌐";
            tooltip-format = "{ifname} via {gwaddr}";
            format-linked = "{ifname} (No IP)";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          pulseaudio = {
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon} 🔵";
            format-bluetooth-muted = "🔇 {icon} 🔵";
            format-muted = "🔇";
            format-icons = {
              headphone = "🎧";
              hands-free = "🎧";
              headset = "🎧";
              phone = "📞";
              portable = "🔊";
              car = "🚗";
              default = [
                "🔈"
                "🔉"
                "🔊"
              ];
            };
            on-click = "pavucontrol";
          };

          tray = {
            spacing = 10;
          };
        };
      };
      style = builtins.readFile ../dotfiles/hyprland/waybar.css;
    };

    # Wofi - Fuzzy finder for applications (never search with eyes)
    programs.wofi = {
      enable = true;
      settings = {
        width = 600;
        height = 400;
        location = "center";
        show = "drun";
        prompt = "Search...";
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

    # Developer-focused scripts
    home.file.".config/hypr/dev_refresh.sh" = {
      text = ''
        #!/bin/bash
        # Refresh developer tools quickly
        pkill waybar && waybar &
        notify-send "Dev tools refreshed"
      '';
      executable = true;
    };

    # Screenshot script for quick captures
    home.file.".config/hypr/screenshot.sh" = {
      text = ''
        #!/bin/bash
        # Quick screenshot to clipboard
        grim -g "$(slurp)" - | wl-copy
        notify-send "Screenshot copied to clipboard"
      '';
      executable = true;
    };

    # Main Hyprland configuration with developer focus
    home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hyprland/hyprland.conf;
  };
}
