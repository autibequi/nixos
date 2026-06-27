#!/usr/bin/env bash
# Rofi launcher workspace-aware: apps abrem no workspace ativo no momento do launch,
# mesmo que demorem. Usa exec rules inline do Hyprland [workspace X silent].
export PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"
WS=$(hyprctl activeworkspace -j | jq -r 'if .name != null and .name != "" then .name else (.id | tostring) end')
exec rofi -show drun -run-command "hyprctl dispatch exec '[workspace ${WS} silent] {cmd}'"
