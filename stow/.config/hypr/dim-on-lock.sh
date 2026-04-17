#!/usr/bin/env bash
# Gradual dim over 5 seconds on lock, then DPMS off. Run in background from hypridle on_lock_cmd.
DURATION=5
STEPS=10
INTERVAL=0.5
for pct in 100 90 80 70 60 50 40 30 20 10 0; do
  brightnessctl set "${pct}%" 2>/dev/null || true
  sleep "$INTERVAL"
done
hyprctl dispatch dpms off
