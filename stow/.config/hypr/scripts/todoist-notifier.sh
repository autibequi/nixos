#!/usr/bin/env bash
# todoist-notifier.sh — daemon: notifica via swaync quando uma tarefa vence agora.
# Executa em loop; lançar via autostart do Hyprland (exec-once).
# Estado: /tmp/todoist-notified  (formato: <task_id>  uma por linha, limpa no reboot)
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

SCRIPT="$HOME/.config/quickshell/modules/todoist/todoist-panel.sh"
STATE="/tmp/todoist-notified"
touch "$STATE"

notify_task() {
    local id="$1" content="$2" due_time="$3"
    notify-send \
        --app-name "Todoist Alarm" \
        --urgency critical \
        --icon "alarm-symbolic" \
        --expire-time 0 \
        "⏰ ${due_time}" \
        "${content}"
    echo "$id" >> "$STATE"
    # sinaliza waybar p/ atualizar o ícone (SIGRTMIN+15)
    pkill -SIGRTMIN+15 waybar 2>/dev/null || true
}

while true; do
    upcoming="$(bash "$SCRIPT" upcoming-alarm 5 2>/dev/null)"
    if [ -n "$upcoming" ] && [ "$upcoming" != "[]" ]; then
        while IFS= read -r task; do
            id="$(echo "$task" | jq -r '.id // empty')"
            content="$(echo "$task" | jq -r '.content // empty')"
            due_time="$(echo "$task" | jq -r '.due_time // "agora"')"
            [ -z "$id" ] && continue
            # notifica só uma vez por task
            if ! grep -qF "$id" "$STATE" 2>/dev/null; then
                notify_task "$id" "$content" "$due_time"
            fi
        done < <(echo "$upcoming" | jq -c '.[]')
    fi
    sleep 60
done
