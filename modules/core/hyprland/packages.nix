{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Core compositor extras
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
    nwg-panel # Painel de controle (volume/brilho/audio out/exit menu)
    wlogout # Power menu GUI (lock/logout/suspend/reboot/shutdown)
    swayosd # On-screen display pra volume/brilho/caps (CLI: swayosd-client)
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
