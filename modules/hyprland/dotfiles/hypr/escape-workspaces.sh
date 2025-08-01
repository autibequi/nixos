#!/usr/bin/env bash
ACTIVE_SPECIAL_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name')

echo "ACTIVE_SPECIAL_WORKSPACE: $ACTIVE_SPECIAL_WORKSPACE"

if [[ "$ACTIVE_SPECIAL_WORKSPACE" =~ ^special:.*$ ]]; then
    # good old hack is simple and works
    hyprctl dispatch togglespecialworkspace "bye!"
    hyprctl dispatch togglespecialworkspace "bye!"
else
    echo "No special workspace found"
fi
