
#!/usr/bin/env bash
ACTIVE_SPECIAL_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name')
echo "ACTIVE_SPECIAL_WORKSPACE: $ACTIVE_SPECIAL_WORKSPACE"

workspace_number="${1}"
echo "workspace_number: $workspace_number"

if [[ "$ACTIVE_SPECIAL_WORKSPACE" =~ ^special:.*$ ]]; then
    # remove special:
    clean_name=$(echo "$ACTIVE_SPECIAL_WORKSPACE" | sed 's/^special://')
    echo "clean_name: $clean_name"
    hyprctl dispatch togglespecialworkspace "$clean_name"
fi

# move to workspace from argument
hyprctl dispatch workspace "$workspace_number"
