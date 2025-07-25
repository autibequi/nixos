#!/bin/sh

current_state=$(gsettings get org.gnome.desktop.interface color-scheme)

if [ "$current_state" = "'prefer-dark'" ]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    swww img ~/.wallpapers/light.jpg --transition-fps 120 --transition-step 200
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    swww img ~/.wallpapers/dark.jpg --transition-fps 120 --transition-step 200
fi
