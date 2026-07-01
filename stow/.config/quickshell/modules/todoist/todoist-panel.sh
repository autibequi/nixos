#!/usr/bin/env bash
# todoist-panel.sh — backend do TodoistWidget (quickshell).
# REST API v1 via curl; o MCP do Todoist está quebrado (410). Quirks em
# memory/reference/todoist_api_v1_curl.md (priority invertido, /close p/ concluir).
# Token: env TODOIST_API_TOKEN, senão ~/.config/todoist/token (fora do git).
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

API="https://api.todoist.com/api/v1"
CLI_CFG="$HOME/.config/todoist/config.json"

# Token: reaproveita o login do todoist CLI (config.json). Fallbacks: env, arquivo simples.
TOKEN="${TODOIST_API_TOKEN:-}"
[ -z "$TOKEN" ] && [ -f "$CLI_CFG" ] && TOKEN="$(jq -r '.token // empty' "$CLI_CFG" 2>/dev/null)"
[ -z "$TOKEN" ] && [ -f "$HOME/.config/todoist/token" ] && TOKEN="$(cat "$HOME/.config/todoist/token")"
[ -z "$TOKEN" ] && { echo '{"error":"no_token"}'; exit 1; }

auth=(-H "Authorization: Bearer $TOKEN")

case "${1:-list}" in
  list)
    # GET /tasks pode vir como array cru ou {results:[...]} (API v1 unificada)
    curl -s "${auth[@]}" "$API/tasks" \
      | jq -c 'def t: if type=="object" and has("results") then .results else . end;
               [ t[] | {id, content, priority, due:(.due.string // ""), project_id} ]' \
      || echo '[]'
    ;;
  projects)
    curl -s "${auth[@]}" "$API/projects" \
      | jq -c 'def t: if type=="object" and has("results") then .results else . end;
               [ t[] | {id, name, inbox:(.is_inbox_project // false)} ]' \
      || echo '[]'
    ;;
  add)
    shift
    content="$*"
    [ -z "$content" ] && { echo '{"error":"empty"}'; exit 1; }
    curl -s "${auth[@]}" -H "Content-Type: application/json" \
      -X POST "$API/tasks" --data "$(jq -n --arg c "$content" '{content:$c}')" \
      | jq -c '{id, content}'
    ;;
  done)
    id="${2:-}"
    [ -z "$id" ] && exit 1
    # concluir = /close (salta recorrente p/ próxima ocorrência)
    curl -s -o /dev/null -w '%{http_code}' "${auth[@]}" -X POST "$API/tasks/$id/close"
    ;;
  *)
    echo '{"error":"usage: list|add <texto>|done <id>"}'; exit 1
    ;;
esac
