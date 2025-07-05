#!/bin/sh
echo "$(date): Starting Hyprland debug script" >> ~/.cache/hyprland/debug.log

# Set environment variables
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

# Create wallpaper if it doesn't exist
if [ ! -f ~/.config/hypr/wallpaper.png ]; then
  ~/.config/hypr/set_wallpaper.sh
fi

# Start essential services with delays
sleep 2
waybar >> ~/.cache/hyprland/waybar.log 2>&1 &

sleep 1
hyprpaper >> ~/.cache/hyprland/hyprpaper.log 2>&1 &

sleep 1
dunst >> ~/.cache/hyprland/dunst.log 2>&1 &

sleep 1
nm-applet --indicator >> ~/.cache/hyprland/nm-applet.log 2>&1 &

echo "$(date): Debug script completed" >> ~/.cache/hyprland/debug.log
