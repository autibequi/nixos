#!/bin/bash

kill $(pgrep waybar -d " ") > /dev/null || true 

waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css &