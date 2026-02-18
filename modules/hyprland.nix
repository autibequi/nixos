{
  lib,
  pkgs,
  inputs,
  pkgs-unstable,
  ...
}:
with lib;
let
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths =
      (with pkgs-unstable.hyprlandPlugins; [
        hyprexpo
        hypr-dynamic-cursors
        hyprfocus
        hyprtrails
        # hyprwinwrap
        # hyprsplit

        # hyprspace
        # hyprscrolling
      ])
      ++ [
        inputs.hyprtasking.packages.${pkgs.system}.hyprtasking
      ];
  };
in
{
  # services.hypridle.enable = true;

  environment.sessionVariables = {
    HYPR_PLUGIN_DIR = hypr-plugin-dir;
    ANYRUN_PLUGIN_DIR = "${pkgs.anyrun}/lib";
  };

  programs.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
    xwayland.enable = true;
  };


  # Habilitar serviço para compilar schemas
  programs.dconf.enable = true;

  # GNOME Keyring - gerenciamento de secrets/senhas/SSH keys
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # HyprPanel via Home Manager (substitui waybar + swaynotificationcenter)
  # Config gerenciado via stow: stow/.config/hyprpanel/config.json
  home-manager.users."pedrinho" = {
    programs.hyprpanel = {
      enable = true;
      systemd.enable = true;
    };
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
    swayimg # Image viewer for Wayland
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

    # Dark/Light Theme Toggle - GTK theming
    glib
    gsettings-desktop-schemas
    dconf-editor # Para debug e edição manual
    gtk3 # Garantir lib GTK3 disponível
    gtk4 # Opcional, se usar apps GTK4
    adw-gtk3 # Tema Adwaita para GTK3 (suporta light/dark)

    # Essential utilities only
    libnotify # Notification support
    pavucontrol # Audio control
    brightnessctl # Screen brightness
    playerctl # Media control

    nwg-displays # Display management
    hyprlock
    cliphist # Clipboard history manager

    # File managers
    yazi # better ranger
    nautilus # file manager
  ];
}
