#!/bin/bash

# Start Hyprland if running on tty1 after logging
[[ $(tty) == /dev/tty1 ]] && exec start-hyprland || hyprland


[[ $(tty) == /dev/tty2 ]] && exec gamescope
