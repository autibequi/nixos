#!/bin/sh

# Get current theme
current_theme=$(gsettings get org.gnome.desktop.interface color-scheme)

# Toggle between dark and light themes
if [[ "$current_theme" == "'prefer-dark'" ]]; then
    # Switch to light theme
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"
    echo "Switched to light theme"
else
    # Switch to dark theme
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
    echo "Switched to dark theme"
fi
