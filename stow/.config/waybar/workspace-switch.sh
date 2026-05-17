#!/usr/bin/env bash
# Oculta special workspace ativo no monitor focado, depois troca pro workspace alvo.
# Replica o comportamento do workspace_switch() do Lua (utils.lua).
target="$1"

special=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .specialWorkspace.name // empty')
if [ -n "$special" ]; then
    name="${special#special:}"
    hyprctl dispatch togglespecialworkspace "$name"
fi

hyprctl dispatch focusworkspaceoncurrentmonitor "$target"
