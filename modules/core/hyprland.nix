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

  # ── Sessão "NVIDIA full offload" ───────────────────────────────────
  # Wrapper que exporta env vars antes de subir o Hyprland. Resultado:
  # o COMPOSITOR e TODOS os clients renderizam na dGPU NVIDIA (RTX 4060).
  # iGPU AMD fica praticamente ociosa — útil quando plugado na tomada
  # ou em sessão de jogo/dev pesado. Pra modo híbrido (compositor na
  # iGPU + offload por app via `gpu-offload`) use a sessão default.
  #
  # WLR_DRM_DEVICES força o wlroots a abrir SÓ o DRM da NVIDIA (bus 1:0:0
  # conforme modules/hardware/nvidia.nix). Sem isso, o compositor pode
  # escolher a iGPU como primary GPU.
  startHyprlandNvidia = pkgs.writeShellScriptBin "start-hyprland-nvidia" ''
    # PRIME render offload globalmente
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only

    # wlroots / Wayland backends apontando pra NVIDIA
    export GBM_BACKEND=nvidia-drm
    export LIBVA_DRIVER_NAME=nvidia
    export WLR_NO_HARDWARE_CURSORS=1

    # Força o wlroots a abrir APENAS o DRM da dGPU (PCI 1:0:0 em nvidia.nix).
    # Sem isso, o compositor pode escolher a iGPU como GPU primária.
    export WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:01:00.0-card

    exec /run/current-system/sw/bin/start-hyprland "$@"
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
    waylandCompositors = {
      # Sessão híbrida (default): compositor roda na iGPU AMD, apps usam
      # `gpu-offload <bin>` (gpu-toggle.nix) pra subir só o que precisa
      # na dGPU NVIDIA. Modo bateria-friendly.
      start-hyprland = {
        prettyName = "Hyprland (Hybrid)";
        comment = "Hyprland on iGPU AMD; apps offload to dGPU via gpu-offload";
        binPath = "/run/current-system/sw/bin/start-hyprland";
      };
      # Sessão NVIDIA full: tudo na dGPU. Selecionar no greeter (tuigreet)
      # quando estiver plugado na tomada / dock.
      start-hyprland-nvidia = {
        prettyName = "Hyprland (NVIDIA full offload)";
        comment = "Hyprland and all clients render on dGPU NVIDIA";
        binPath = "${startHyprlandNvidia}/bin/start-hyprland-nvidia";
      };
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

  # SwayOSD — overlay visual pra volume/brilho/caps lock.
  # NixOS não tem módulo `services.swayosd`; subimos o daemon como systemd
  # user service. `swayosd-client --output-volume/--brightness/--caps-lock`
  # fala com ele via dbus. Backend opcional pra caps-lock LED roda como
  # systemd system service (não habilitado aqui — caps via bind no Hyprland).
  systemd.user.services.swayosd = {
    description = "SwayOSD server (volume/brightness/caps OSD)";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

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
    startHyprlandNvidia
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
    nwg-panel   # Painel de controle (volume/brilho/audio out/exit menu)
    wlogout     # Power menu GUI (lock/logout/suspend/reboot/shutdown)
    swayosd     # On-screen display pra volume/brilho/caps (CLI: swayosd-client)
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
