#!/usr/bin/env bash
# Wake all monitors from DPMS sleep — works with multi-display setups
# Called by hypridle on unlock and after sleep

# Get all connected monitors and wake each one
hyprctl monitors -j | jq -r '.[].name' | while read -r monitor; do
    hyprctl dispatch dpms on "$monitor" 2>/dev/null || true
done

exit 0
