{ pkgs, hyprlandWaybar, ... }:
{
  environment.systemPackages = with pkgs; [
    # ── Hyprland ecosystem ────────────────────────────────────────────
    hyprpicker # color picker
    hyprshade # shader manager (night light, etc.)
    hyprlock # lock screen
    hyprls # language server pra Hyprland config
    hyprpolkitagent # polkit agent (config em services.nix)

    # ── Bar / launcher / notifications / OSD ──────────────────────────
    hyprlandWaybar # status bar (patched for Hyprland Lua dispatch syntax)
    walker # app launcher / command palette frontend
    elephant # Walker providers backend (apps, calc, files, clipboard, etc.)
    swaynotificationcenter # notifications daemon
    # dunst # alternativa a swaync (desativado)
    nwg-panel # painel de controle (volume/brilho/audio out/exit menu)
    swayosd # OSD pra volume/brilho/caps (CLI: swayosd-client)
    libnotify # notify-send CLI / lib

    # ── Terminais ─────────────────────────────────────────────────────
    alacritty # default
    ghostty # kitty-graphics protocol (yazi image preview)

    # ── Screenshots / capture / OCR ───────────────────────────────────
    grim # screenshot
    slurp # region select
    satty # annotation
    swayimg # image viewer (Wayland)
    wf-recorder # screen recording
    tesseract # OCR

    # ── Wallpaper / cursor / theming ──────────────────────────────────
    awww # wallpaper daemon (awww renomeado em 26.05)

    # hyprcursor (Wayland nativo, vetorial)
    rose-pine-hyprcursor
    # xcursor legacy (bitmap) — fallback para apps XWayland (Chrome/Electron com
    # --ozone-platform=x11). Sem isso, XWayland usa default ~16px → cursor minúsculo.
    rose-pine-cursor
    # xrdb — sem isso `hyprctl setcursor` não consegue propagar o size do
    # cursor pro Xresources do XWayland; apps X11 leem o size só do Xresources
    # (env var XCURSOR_SIZE não basta) → cursor fica no default 16px mesmo
    # com tema correto.
    xrdb

    # SVG icon rendering (needed by rofi show-icons with Papirus)
    librsvg

    # Dark/Light Theme Toggle — GTK theming
    glib # gsettings CLI
    gsettings-desktop-schemas
    gtk3
    adw-gtk3 # tema Adwaita pra GTK3 (suporta light/dark)

    # ── Clipboard ─────────────────────────────────────────────────────
    wl-clipboard # wl-copy / wl-paste
    cliphist # history manager
    wtype # injeção de teclas/texto no Wayland (usado em keybinds: SUPER+WASD→setas, CTRL+ALT+V)

    # ── Audio / brightness / media controls ───────────────────────────
    pavucontrol # GUI de audio (PipeWire/PulseAudio)
    wiremix # TUI mixer
    brightnessctl # screen brightness
    playerctl # MPRIS media control

    # ── Display / monitors ────────────────────────────────────────────
    nwg-displays # configurador de outputs

    # ── Power menu / sessão ───────────────────────────────────────────
    wlogout # GUI (lock/logout/suspend/reboot/shutdown)

    # ── Bluetooth ─────────────────────────────────────────────────────
    bluetuith # TUI

    # ── File managers / preview ───────────────────────────────────────
    yazi # better ranger (TUI)
    nautilus # GTK file manager
    gnome-disk-utility
    poppler-utils # PDF preview (pdftoppm)
    ffmpegthumbnailer # video thumbnails

    # ── Qt / Wayland support / outros GUIs ────────────────────────────
    quickshell # Qt-based shell toolkit
    qt6.qtwayland # Qt6 Wayland platform
    zenity # GTK dialogs (file picker, info, etc.)
    cheese # webcam (GNOME)
  ];
}
