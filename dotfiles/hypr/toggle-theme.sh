#!/bin/sh

current_state=$(gsettings get org.gnome.desktop.interface color-scheme)

echo $current_state

# Alterna usando o estado salvo
if [ "$current_state" = "'prefer-dark'" ]; then
    # Muda para light
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    echo "Switched to light theme"
    swww img ~/.wallpapers/light.jpg
else
    # Muda para dark
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    echo "Switched to dark theme"
    swww img ~/.wallpapers/dark.jpg
fi
