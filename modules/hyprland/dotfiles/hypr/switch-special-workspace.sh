
#!/usr/bin/env bash
workspace_number="${1}"

echo "$workspace_number" > /tmp/last_special_workspace

# move to workspace from argument
hyprctl dispatch togglespecialworkspace "$workspace_number"
