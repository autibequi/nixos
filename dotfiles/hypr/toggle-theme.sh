#!/bin/sh

STATE_FILE="/tmp/hypr-theme-state"


if [ -f "$STATE_FILE" ]; then
    current_state=$(cat "$STATE_FILE")
else
    current_state="dark"
fi

# Alterna usando o estado salvo
if [ "$current_state" = "dark" ]; then
    # Muda para light
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    echo "light" > "$STATE_FILE"
    echo "Switched to light theme"
    swww img ~/.wallpapers/light.jpg
else
    # Muda para dark
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    echo "dark" > "$STATE_FILE"
    echo "Switched to dark theme"
    swww img ~/.wallpapers/dark.jpg
fi
