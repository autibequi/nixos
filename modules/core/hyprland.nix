{
  lib,
  pkgs,
  hyprlandFlake,
  ...
}:
with lib;
let
  # Mesmo conteúdo para qualquer DESKTOP que o xdg-desktop-portal procure primeiro
  # (ex.: XDG_CURRENT_DESKTOP=uwsm:Hyprland → lê uwsm-portals.conf antes de hyprland).
  hyprPortalPreferred = ''
    [preferred]
    default=hyprland;gtk
    org.freedesktop.impl.portal.Settings=gtk
  '';
in
{
  programs.hyprland = {
    enable = true;
    package = hyprlandFlake.hyprland;
    xwayland.enable = true;
    withUWSM = true;
  };

  programs.uwsm = {
    enable = true;
    package = pkgs.uwsm;
    waylandCompositors.start-hyprland = {
      prettyName = "Start-Hyprland ";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/start-hyprland";
    };
  };

  # Habilitar serviço para compilar schemas
  programs.dconf.enable = true;

  # sinais do sistema como color-scheme (dark/light), file picker, screen share
  xdg.portal = {
    enable = true;
    # mkForce evita duplicata: programs.hyprland (withUWSM) também adiciona hyprland portal
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # handles Settings portal (color-scheme)
    ];
    config = {
      # Para sessões Hyprland: hyprland portal primeiro, gtk como fallback
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        # Settings (color-scheme dark/light) — só gtk implementa
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
      # Fallback: sem ficheiro *-portals.conf específico, ou último na lista DE
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
  };

  # programs.hyprland / pacotes podem instalar hyprland-portals.conf minimalista.
  # Garantimos Settings→gtk para hyprland e uwsm (ver hyprPortalPreferred).
  environment.etc = {
    "xdg/xdg-desktop-portal/hyprland-portals.conf".text = lib.mkForce hyprPortalPreferred;
    "xdg/xdg-desktop-portal/uwsm-portals.conf".text = lib.mkForce hyprPortalPreferred;
  };

  # GNOME Keyring - gerenciamento de secrets/senhas/SSH keys
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # HyprIdle
  services.hypridle.enable = true;

  # hyprpolkitagent tem Restart=on-failure no unit original. Quando Hyprland morre
  # (ex: nixos-rebuild switch mata serviços gráficos), o agent reinicia sem
  # WAYLAND_DISPLAY → Qt6 explode com SIGABRT → loop infinito de crashes.
  # StartLimitBurst=3 deixa tentar 3x antes de desistir, quebrando o loop.
  systemd.user.services.hyprpolkitagent = {
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 30;
    };
  };

  # Register librsvg as gdk-pixbuf SVG loader (fixes SVG icons in rofi, waybar, etc)
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

  environment.systemPackages = with pkgs; [
    quickshell
    qt6.qtwayland
    zenity
    hyprpicker
    wf-recorder
    hyprpolkitagent
    cheese

    # Core Hyprland tools for navigation and productivity
    waybar # Status bar with useful info
    wofi # App launcher (fuzzy finding)
    alacritty # Terminal
    # dunst # Notifications
    swaynotificationcenter # Notifications
    grim # Screenshots
    slurp # Screen selection
    swayimg # Image viewer for Wayland
    wl-clipboard # Clipboard management
    hyprshade
    swww
    bluetuith
    wiremix
    tesseract
    satty

    # hyprcursor (Wayland nativo, vetorial)
    rose-pine-hyprcursor
    # xcursor legacy (bitmap) — fallback para apps XWayland (Chrome/Electron com
    # --ozone-platform=x11). Sem isso, XWayland usa default ~16px → cursor minúsculo.
    rose-pine-cursor
    # xrdb — sem isso `hyprctl setcursor` não consegue propagar o size do
    # cursor pro Xresources do XWayland; apps X11 leem o size só do Xresources
    # (env var XCURSOR_SIZE não basta) → cursor fica no default 16px mesmo
    # com tema correto.
    xorg.xrdb

    # SVG icon rendering (needed by rofi show-icons with Papirus)
    librsvg

    # Dark/Light Theme Toggle - GTK theming
    glib # gsettings CLI
    gsettings-desktop-schemas
    gtk3
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
    hyprls # Language Server for Hyprland config files
    cliphist # Clipboard history manager

    # File managers
    yazi # better ranger
    ghostty # terminal with kitty graphics protocol (for yazi image preview)
    poppler-utils # PDF preview (pdftoppm)
    ffmpegthumbnailer # video thumbnails
    nautilus # file manager
  ];
}
