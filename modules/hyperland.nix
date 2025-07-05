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
    services.dunst = {
      enable = true;
      settings = {
        global = {
          font = "JetBrainsMono Nerd Font 11";
          format = "<b>%s</b>\n%b";
          sort = true;
          indicate_hidden = true;
          alignment = "left";
          show_age_threshold = 60;
          word_wrap = true;
          ignore_newline = false;
          geometry = "300x5-30+20";
          shrink = false;
          transparency = 0;
          idle_threshold = 120;
          monitor = 0;
          follow = "mouse";
          sticky_history = true;
          history_length = 20;
          show_indicators = true;
          line_height = 0;
          separator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          separator_color = "frame";
          startup_notification = false;
          dmenu = "${pkgs.wofi}/bin/wofi -p dunst";
          browser = "${pkgs.firefox}/bin/firefox -new-tab";
          icon_position = "left";
          max_icon_size = 32;
          frame_width = 3;
          frame_color = "#aaaaaa";
        };
        urgency_low = {
          background = "#222222";
          foreground = "#888888";
          timeout = 10;
        };
        urgency_normal = {
          background = "#285577";
          foreground = "#ffffff";
          timeout = 10;
        };
        urgency_critical = {
          background = "#900000";
          foreground = "#ffffff";
          frame_color = "#ff0000";
          timeout = 0;
        };
      };
    };

    # Waybar configuration
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 40;
          spacing = 4;
          modules-left = [
            "hyprland/workspaces"
            "hyprland/window"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "pulseaudio"
            "network"
            "cpu"
            "memory"
            "battery"
            "tray"
          ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "10";
              urgent = "";
              focused = "";
              default = "";
            };
          };

          "hyprland/window" = {
            format = "{}";
            max-length = 50;
          };

          clock = {
            format = "{:%Y-%m-%d %H:%M:%S}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            interval = 1;
          };

          pulseaudio = {
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };

          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          cpu = {
            format = "{usage}% ";
            tooltip = false;
          };

          memory = {
            format = "{}% ";
          };

          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-plugged = "{capacity}% ";
            format-alt = "{time} {icon}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };

          tray = {
            icon-size = 21;
            spacing = 10;
          };
        };
      };

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 14px;
        }

        window#waybar {
          background-color: rgba(43, 48, 59, 0.8);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: 0.5s;
        }

        button {
          box-shadow: inset 0 -3px transparent;
          border: none;
          border-radius: 0;
        }

        button:hover {
          background: inherit;
          box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
        }

        #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
        }

        #workspaces button.active {
          background-color: #64727d;
          box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button.urgent {
          background-color: #eb4d4b;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #pulseaudio,
        #network,
        #tray {
          padding: 0 10px;
          color: #ffffff;
        }

        #window {
          margin: 0 4px;
        }

        #battery.charging, #battery.plugged {
          color: #26a65b;
        }

        #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }

        #pulseaudio.muted {
          color: #a3a3a3;
        }

        #network.disconnected {
          color: #f53c3c;
        }
      '';
    };

    # Create a simple solid color wallpaper script
    home.file.".config/hypr/set_wallpaper.sh" = {
      text = ''
        #!/bin/sh
        # Create a simple solid color wallpaper using ImageMagick
        convert -size 1920x1080 "gradient:#1e1e2e-#313244" ~/.config/hypr/wallpaper.png
      '';
      executable = true;
    };

    # Hyprpaper configuration for wallpaper
    home.file.".config/hypr/hyprpaper.conf".text = ''
      preload = ~/.config/hypr/wallpaper.png
      wallpaper = ,~/.config/hypr/wallpaper.png
      splash = false
      ipc = on
    '';

    # Main Hyprland configuration
    home.file.".config/hypr/hyprland.conf".text = ''
      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor=,preferred,auto,1

      # Execute your favorite apps at launch
      # IMPORTANT: Don't run swaylock on startup as it locks the screen immediately
      exec-once = ~/.config/hypr/set_wallpaper.sh
      exec-once = waybar
      exec-once = hyprpaper
      exec-once = dunst
      exec-once = nm-applet --indicator
      exec-once = ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1

      # Set programs that you use
      $terminal = alacritty
      $fileManager = dolphin
      $menu = wofi --show drun
      $lock = swaylock-effects

      # Some default env vars.
      env = XCURSOR_SIZE,24
      env = GDK_BACKEND,wayland,x11
      env = QT_QPA_PLATFORM,wayland;xcb
      env = SDL_VIDEODRIVER,wayland
      env = CLUTTER_BACKEND,wayland
      env = MOZ_ENABLE_WAYLAND,1

      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =

          follow_mouse = 1

          touchpad {
              natural_scroll = false
          }

          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
      }

      general {
          gaps_in = 5
          gaps_out = 20
          border_size = 2
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
          allow_tearing = false
      }

      decoration {
          rounding = 10

          blur {
              enabled = true
              size = 3
              passes = 1
              vibrancy = 0.1696
          }

          drop_shadow = true
          shadow_range = 4
          shadow_render_power = 3
          col.shadow = rgba(1a1a1aee)
      }

      animations {
          enabled = true
          bezier = myBezier, 0.05, 0.9, 0.1, 1.05
          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = borderangle, 1, 8, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }

      dwindle {
          pseudotile = true
          preserve_split = true
      }

      master {
          new_is_master = true
      }

      gestures {
          workspace_swipe = false
      }

      misc {
          force_default_wallpaper = -1
          disable_hyprland_logo = false
      }

      # Window rules
      windowrulev2 = nomaximizerequest, class:.*

      # Keybindings
      $mainMod = SUPER

      # Basic binds
      bind = $mainMod, Q, exec, $terminal
      bind = $mainMod, C, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, V, togglefloating,
      bind = $mainMod, R, exec, $menu
      bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, J, togglesplit, # dwindle
      bind = $mainMod, F, fullscreen, 0

      # Custom binds
      bind = $mainMod, L, exec, $lock
      bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
      bind = $mainMod, Print, exec, grim ~/Pictures/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png

      # Audio controls
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind = , XF86AudioPlay, exec, playerctl play-pause
      bind = , XF86AudioPause, exec, playerctl play-pause
      bind = , XF86AudioNext, exec, playerctl next
      bind = , XF86AudioPrev, exec, playerctl previous

      # Brightness controls
      bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
      bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      # Move focus with mainMod + hjkl (vim keys)
      bind = $mainMod, h, movefocus, l
      bind = $mainMod, l, movefocus, r
      bind = $mainMod, k, movefocus, u
      bind = $mainMod, j, movefocus, d

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      # Resize windows
      bind = $mainMod ALT, left, resizeactive, -20 0
      bind = $mainMod ALT, right, resizeactive, 20 0
      bind = $mainMod ALT, up, resizeactive, 0 -20
      bind = $mainMod ALT, down, resizeactive, 0 20

      # Move windows
      bind = $mainMod SHIFT, left, movewindow, l
      bind = $mainMod SHIFT, right, movewindow, r
      bind = $mainMod SHIFT, up, movewindow, u
      bind = $mainMod SHIFT, down, movewindow, d

      # Special workspace (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
    '';
  };
}
