#!/usr/bin/env bash
# todoist-status.sh — retorna JSON para o módulo custom/todoist do waybar.
# Saída: {"text":"󰄲 [N]","class":"[overdue|]","tooltip":"..."}
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

SCRIPT="$HOME/.config/quickshell/modules/todoist/todoist-panel.sh"

result="$(bash "$SCRIPT" status 2>/dev/null)"
[ -z "$result" ] && result='{"text":"󰄲","class":"","tooltip":""}'
printf '%s\n' "$result"
