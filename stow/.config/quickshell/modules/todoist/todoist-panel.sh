#!/usr/bin/env bash
# todoist-panel.sh — backend do TodoistWidget (quickshell).
# REST API v1 via curl; o MCP do Todoist está quebrado (410). Quirks em
# memory/reference/todoist_api_v1_curl.md (priority invertido, /close p/ concluir).
# Token: reaproveita o login do todoist CLI (~/.config/todoist/config.json).
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

API="https://api.todoist.com/api/v1"
CLI_CFG="$HOME/.config/todoist/config.json"

TOKEN="${TODOIST_API_TOKEN:-}"
[ -z "$TOKEN" ] && [ -f "$CLI_CFG" ] && TOKEN="$(jq -r '.token // empty' "$CLI_CFG" 2>/dev/null)"
[ -z "$TOKEN" ] && [ -f "$HOME/.config/todoist/token" ] && TOKEN="$(cat "$HOME/.config/todoist/token")"
[ -z "$TOKEN" ] && { echo '{"error":"no_token"}'; exit 1; }

auth=(-H "Authorization: Bearer $TOKEN")

# fetch_all <path> [extra_query] — pagina seguindo next_cursor (a API v1 corta em 50)
# e devolve um único array JSON com todos os itens (results concatenados).
fetch_all() {
  local path="$1" extra="${2:-}" cursor="" page acc="[]" sep
  while :; do
    sep="?"; [ -n "$extra" ] && sep="?${extra}&"
    if [ -n "$cursor" ]; then
      page="$(curl -s "${auth[@]}" "${API}${path}${sep}limit=200&cursor=${cursor}")"
    else
      page="$(curl -s "${auth[@]}" "${API}${path}${sep}limit=200")"
    fi
    [ -z "$page" ] && break
    acc="$(jq -c --argjson acc "$acc" \
      'def t: if type=="object" and has("results") then .results else . end; $acc + t' <<<"$page")" || break
    cursor="$(jq -r 'if type=="object" then (.next_cursor // "") else "" end' <<<"$page")"
    [ -z "$cursor" ] || [ "$cursor" = "null" ] && break
  done
  printf '%s' "$acc"
}

case "${1:-list}" in
  list)
    fetch_all "/tasks" \
      | jq -c '[ .[] | {
          id, content, priority,
          due:        (.due.string   // ""),
          due_date:   (.due.date     // null),
          due_datetime:(.due.datetime // null),
          due_time:   (
            # Todoist API v1: tarefas com hora local têm o datetime em .due.date
            # (sem TZ, ex: "2026-07-01T07:00:00") e .due.datetime é null.
            # Tarefas com TZ explícito têm .due.datetime com sufixo Z.
            if .due.datetime then (.due.datetime | capture("T(?<t>[0-9]{2}:[0-9]{2})").t)
            elif (.due.date // "") | test("T") then (.due.date | capture("T(?<t>[0-9]{2}:[0-9]{2})").t)
            else null end
          ),
          project_id, section_id
        } ]' \
      || echo '[]'
    ;;
  projects)
    fetch_all "/projects" \
      | jq -c '[ .[] | {id, name, inbox:(.is_inbox_project // false)} ]' || echo '[]'
    ;;
  sections)
    fetch_all "/sections" \
      | jq -c '[ .[] | {id, name, project_id} ]' || echo '[]'
    ;;
  inbox-id)
    fetch_all "/projects" \
      | jq -r 'first(.[] | select(.is_inbox_project==true or .name=="Inbox") | .id) // empty'
    ;;
  menu-inbox)
    # TSV (id<TAB>content) só do Inbox — fácil de parsear no Lua do Elephant
    pid="$(fetch_all "/projects" | jq -r 'first(.[] | select(.is_inbox_project==true or .name=="Inbox") | .id) // empty')"
    [ -z "$pid" ] && exit 0
    fetch_all "/tasks" "project_id=$pid" | jq -r '.[] | "\(.id)\t\(.content)"'
    ;;
  add)
    # add <texto> [project_id] [section_id] — cria no projeto/seção ativos (ou Inbox)
    content="${2:-}"; project="${3:-}"; section="${4:-}"
    [ -z "$content" ] && { echo '{"error":"empty"}'; exit 1; }
    body="$(jq -n --arg c "$content" '{content:$c}')"
    [ -n "$project" ] && body="$(jq --arg p "$project" '. + {project_id:$p}' <<<"$body")"
    [ -n "$section" ] && body="$(jq --arg s "$section" '. + {section_id:$s}' <<<"$body")"
    curl -s "${auth[@]}" -H "Content-Type: application/json" \
      -X POST "$API/tasks" --data "$body" | jq -c '{id, content, project_id, section_id}'
    ;;
  done)
    id="${2:-}"
    [ -z "$id" ] && exit 1
    # concluir = /close (salta recorrente p/ próxima ocorrência)
    curl -s -o /dev/null -w '%{http_code}' "${auth[@]}" -X POST "$API/tasks/$id/close"
    ;;
  drop)
    # drag-and-drop: move a task p/ a seção destino + reordena a seção toda (Sync API).
    # args: $2=task_id  $3=section(none|<id>)  $4=project_id  $5=csv de ids na ordem final
    id="${2:-}"; sec="${3:-none}"; proj="${4:-}"; order="${5:-}"
    [ -z "$id" ] && exit 1
    _uuid() { cat /proc/sys/kernel/random/uuid; }
    if [ "$sec" = "none" ]; then
      mv=$(jq -n --arg u "$(_uuid)" --arg i "$id" --arg p "$proj" '{type:"item_move",uuid:$u,args:{id:$i,project_id:$p}}')
    else
      mv=$(jq -n --arg u "$(_uuid)" --arg i "$id" --arg s "$sec" '{type:"item_move",uuid:$u,args:{id:$i,section_id:$s}}')
    fi
    if [ -n "$order" ]; then
      items=$(printf '%s' "$order" | tr ',' '\n' | awk 'NF{printf "{\"id\":\"%s\",\"child_order\":%d},",$0,NR}' | sed 's/,$//')
      ro=$(jq -n --arg u "$(_uuid)" --argjson it "[$items]" '{type:"item_reorder",uuid:$u,args:{items:$it}}')
      body=$(jq -n --argjson m "$mv" --argjson r "$ro" '{commands:[$m,$r]}')
    else
      body=$(jq -n --argjson m "$mv" '{commands:[$m]}')
    fi
    curl -s "${auth[@]}" -H "Content-Type: application/json" -X POST "$API/sync" --data "$body" | jq -c '.sync_status'
    ;;
  status)
    # Retorna JSON para waybar: {"text":"...","class":"","tooltip":"..."}
    TODAY="$(date +%Y-%m-%d)"
    NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%S)"
    tasks="$(fetch_all "/tasks" 2>/dev/null)" || tasks="[]"
    counts="$(echo "$tasks" | jq -c \
      --arg today "$TODAY" --arg now "$NOW_ISO" '
        [.[] | {
          d: (.due.date     // null),
          dt:(.due.datetime // null)
        }] |
        {
          overdue: [ .[] | select(
            .d != null and (
              .d < $today or
              (.d == $today and .dt != null and .dt <= $now)
            )
          )] | length,
          upcoming: [ .[] | select(
            .d != null and .d == $today and
            (.dt == null or .dt > $now)
          )] | length
        }
      ' 2>/dev/null)" || counts='{"overdue":0,"upcoming":0}'
    overdue="$(echo "$counts" | jq -r '.overdue // 0')"
    upcoming="$(echo "$counts" | jq -r '.upcoming // 0')"
    if [ "${overdue:-0}" -gt 0 ] 2>/dev/null; then
      printf '{"text":"󰄲 %s","class":"overdue","tooltip":"%s atrasada(s) | %s hoje"}\n' \
        "$overdue" "$overdue" "$upcoming"
    else
      printf '{"text":"󰄲","class":"","tooltip":"%s tarefa(s) hoje"}\n' "$upcoming"
    fi
    ;;

  upcoming-alarm)
    # Tarefas com due.datetime nos próximos N minutos (padrão 5); para o daemon de notificação.
    WINDOW="${2:-5}"
    NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%S)"
    FUTURE_ISO="$(date -u -d "+${WINDOW} minutes" +%Y-%m-%dT%H:%M:%S 2>/dev/null \
                || date -u -v "+${WINDOW}M" +%Y-%m-%dT%H:%M:%S 2>/dev/null)"
    fetch_all "/tasks" \
      | jq -c --arg now "$NOW_ISO" --arg fut "$FUTURE_ISO" '
          [ .[] | select(.due.datetime != null)
                | select(.due.datetime > $now and .due.datetime <= $fut)
                | {id, content, due_time: (.due.datetime | capture("T(?<t>[0-9]{2}:[0-9]{2})").t)} ]
        ' 2>/dev/null || echo '[]'
    ;;

  save-scope)
    # Persiste o scope/sectionScope selecionado — sobrevive restart do quickshell.
    STATE_DIR="$HOME/.cache/todoist-widget"
    mkdir -p "$STATE_DIR"
    printf '%s\n%s\n' "${2:-all}" "${3:-all}" > "$STATE_DIR/scope"
    ;;

  load-scope)
    STATE_FILE="$HOME/.cache/todoist-widget/scope"
    if [ -f "$STATE_FILE" ]; then
      scope="$(sed -n '1p' "$STATE_FILE")"
      section="$(sed -n '2p' "$STATE_FILE")"
      jq -cn --arg scope "${scope:-all}" --arg section "${section:-all}" \
        '{scope: $scope, sectionScope: $section}'
    else
      echo '{"scope":"all","sectionScope":"all"}'
    fi
    ;;

  *)
    echo '{"error":"usage: list|projects|sections|inbox-id|menu-inbox|add|done|drop|status|upcoming-alarm|save-scope|load-scope"}'; exit 1
    ;;
esac
