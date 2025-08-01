#!/usr/bin/env bash

ACTIVE_SPECIAL_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name')

echo "ACTIVE_SPECIAL_WORKSPACE: $ACTIVE_SPECIAL_WORKSPACE"

if [[ "$ACTIVE_SPECIAL_WORKSPACE" =~ ^special:.*$ ]]; then
    echo "Toggling special workspace: $ACTIVE_SPECIAL_WORKSPACE"
    hyprctl dispatch togglespecialworkspace "$ACTIVE_SPECIAL_WORKSPACE"
else
    echo "No special workspace found"
fi
