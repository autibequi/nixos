#!/bin/sh

hypridle \
    timeout 300 'hyprlock' \
    timeout 600 'systemctl suspend' \
    timeout 900 'systemctl hibernate' \
    before-sleep 'hyprlock'
