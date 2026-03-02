#!/bin/sh
# Theme logic: dark_theme, light_theme, toggle_theme.
# Sourced by hyprutils.sh.

THEME_STATE_FILE="${HOME}/.cache/hyprland/hyprutils_theme_state"
ALACRITTY_CONFIG="${HOME}/.config/alacritty/alacritty.toml"
WALLPAPER_DARK="${HOME}/assets/wallpapers/the-wild-hunt-of-odin.jpg"
WALLPAPER_LIGHT="${HOME}/assets/wallpapers/the-death-of-socrates.jpg"

apply_gtk_theme() {
    local gtk_theme="$1"
    local color_scheme="$2"

    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-application-prefer-dark-theme=$([ "$color_scheme" = "prefer-dark" ] && echo "1" || echo "0")
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-enable-animations=true
EOF

    mkdir -p "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-application-prefer-dark-theme=$([ "$color_scheme" = "prefer-dark" ] && echo "1" || echo "0")
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-enable-animations=true
EOF

    if command -v gsettings &> /dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
    fi

    if command -v dconf &> /dev/null; then
        dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'" 2>/dev/null || true
    fi

    export GTK_THEME="$gtk_theme"
    killall -SIGHUP xsettingsd 2>/dev/null || true
}

dark_theme() {
    mkdir -p "$HOME/.cache/hyprland"
    echo "dark" > "$THEME_STATE_FILE"

    apply_gtk_theme "adw-gtk3-dark" "prefer-dark"

    if [ -f "$ALACRITTY_CONFIG" ]; then
        sed -i 's|import = \["~/.config/alacritty/light-theme.toml"\]|import = ["~/.config/alacritty/dark-theme.toml"]|g' "$ALACRITTY_CONFIG"
    fi

    if [ -f "$WALLPAPER_DARK" ]; then
        swww img "$WALLPAPER_DARK" \
            --transition-type fade \
            --transition-fps 60 \
            --transition-duration 0.3
    fi
}

light_theme() {
    mkdir -p "$HOME/.cache/hyprland"
    echo "light" > "$THEME_STATE_FILE"

    apply_gtk_theme "adw-gtk3" "prefer-light"

    if [ -f "$ALACRITTY_CONFIG" ]; then
        sed -i 's|import = \["~/.config/alacritty/dark-theme.toml"\]|import = ["~/.config/alacritty/light-theme.toml"]|g' "$ALACRITTY_CONFIG"
    fi

    if [ -f "$WALLPAPER_LIGHT" ]; then
        swww img "$WALLPAPER_LIGHT" \
            --transition-type fade \
            --transition-fps 60 \
            --transition-duration 0.3
    fi
}

toggle_theme() {
    local current_theme

    mkdir -p "$HOME/.cache/hyprland"
    if [ -f "$THEME_STATE_FILE" ]; then
        current_theme=$(cat "$THEME_STATE_FILE")
    else
        current_theme="dark"
    fi

    if [ "$current_theme" = "dark" ]; then
        light_theme
        notify-send -t 500 "Theme changed to light ☀️"
    else
        dark_theme
        notify-send -t 500 "Theme changed to dark 🌙"
    fi
}
