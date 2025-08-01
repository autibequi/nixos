#!/usr/bin/env bash
ACTIVE_SPECIAL_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name')

echo "ACTIVE_SPECIAL_WORKSPACE: $ACTIVE_SPECIAL_WORKSPACE"

if [[ "$ACTIVE_SPECIAL_WORKSPACE" =~ ^special:.*$ ]]; then
    # remove special:
    clean_name=$(echo "$ACTIVE_SPECIAL_WORKSPACE" | sed 's/^special://')
    hyprctl dispatch togglespecialworkspace "$clean_name"

else
    # Envia um evento de tecla ESC para o bus do Hyprland (simula pressionar ESC)
    echo "No special workspace found"
fi

workspace_number="${1}"

echo "workspace_number: $workspace_number"

# move to workspace from argument
hyprctl dispatch workspace "$workspace_number"