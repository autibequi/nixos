#!/bin/bash
# Refresh developer tools quickly
pkill waybar && waybar &
notify-send "Dev tools refreshed"