#!/bin/sh

# Hyperland cant read directly from gsettings for whatever reason
state_file="/tmp/theme"

if [ -f "$state_file" ]; then
    current_state=$(cat "$state_file")
else
    current_state="dark"
fi

# Alterna usando o estado salvo
if [ "$current_state" = "dark" ]; then
    # Muda para light
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    echo "Switched to light theme"
    swww img ~/.wallpapers/light.jpg
    echo "light" > "$state_file"
else
    # Muda para dark
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    echo "Switched to dark theme"
    swww img ~/.wallpapers/dark.jpg
fi

