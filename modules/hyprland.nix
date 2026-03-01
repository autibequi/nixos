{
  lib,
  pkgs,
  inputs,
  hyprland-git,
  pkgs-unstable,
  ...
}:
with lib;
let
  # Hyprland Plugins
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths =
      (with pkgs-unstable.hyprlandPlugins; [
        hyprexpo
        hypr-dynamic-cursors
        # hyprfocus
        # hyprtrails
        # hyprspace
      ])
      ++ [
        # inputs.hyprtasking.packages.${pkgs.system}.hyprtasking
      ];
  };
in
{
  programs.hyprland = {
    enable = true;
    package = hyprland-git.hyprland;
    xwayland.enable = true;
    withUWSM = true;
  };

  programs.uwsm.package = pkgs-unstable.uwsm;

  # Environment Variables
  environment.sessionVariables = {
    HYPR_PLUGIN_DIR = hypr-plugin-dir;
  };

  # Habilitar serviço para compilar schemas
  programs.dconf.enable = true;

  # GNOME Keyring - gerenciamento de secrets/senhas/SSH keys
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # HyprIdle
  services.hypridle.enable = true;

  environment.systemPackages = with pkgs; [
    zenity
    hyprpicker
    hyprpolkitagent
    cheese

    pkgs-unstable.uwsm

    # Core Hyprland tools for navigation and productivity
    waybar # Status bar with useful info
    wofi # App launcher (fuzzy finding)
    alacritty # Terminal
    # dunst # Notifications
    swaynotificationcenter # Notifications
    grim # Screenshots
    hyprshot # Screenshots
    swappy # Screen editing
    slurp # Screen selection
    swayimg # Image viewer for Wayland
    wl-clipboard # Clipboard management
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

    # Gnome Oldies
    gnome-disk-utility

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
