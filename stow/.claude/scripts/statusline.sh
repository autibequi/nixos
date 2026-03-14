#!/bin/bash
# Status line com deteccao automatica de topico via ultima msg do user
# Recebe JSON do Claude Code: model, workspace, context_window, cost, session_id, worktree, etc.
# Output stdout: status line visivel (plain text; widget nao interpreta ANSI)
# Output stderr: terminal title (OSC) pro Hyprland/waybar
# Debug: DEBUG_STATUSLINE=1 salva o JSON em .ephemeral/statusline-input.json

input=$(cat)

# Debug: dump JSON para inspecao
if [[ -n "${DEBUG_STATUSLINE:-}" ]]; then
  echo "$input" > "${WS:-/workspace}/.ephemeral/statusline-input.json" 2>/dev/null || true
fi

# Dados do JSON (schema: code.claude.com/docs/en/statusline)
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
# Uso em tokens: current_usage (input+cache) ou estimado a partir de used_percentage
CTX_USED=$(echo "$input" | jq -r '
  if .context_window.current_usage then
    (.context_window.current_usage.input_tokens // 0) +
    (.context_window.current_usage.cache_creation_input_tokens // 0) +
    (.context_window.current_usage.cache_read_input_tokens // 0)
  else
    (if .context_window.context_window_size > 0 and .context_window.used_percentage then
      (.context_window.context_window_size * (.context_window.used_percentage / 100)) | floor
     else 0 end)
  end
')
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')
WORKSPACE_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
WORKTREE_NAME=$(echo "$input" | jq -r '.worktree.name // .worktree.branch // ""')

# Extrair topico da ultima mensagem do user no transcript
TOPIC=""
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  # Pega a ultima linha com role=user e extrai o texto
  TOPIC=$(grep '"role":"user"' "$TRANSCRIPT" 2>/dev/null \
    | tail -1 \
    | jq -r '
      .message.content
      | if type == "string" then .
        elif type == "array" then
          map(select(.type == "text") | .text) | join(" ")
        else ""
        end
    ' 2>/dev/null)
fi

# Fallback se nao encontrou topico
if [[ -z "$TOPIC" || "$TOPIC" == "null" ]]; then
  TOPIC="nova sessao"
fi

# Limpar e truncar topico (~40 chars)
TOPIC=$(echo "$TOPIC" | tr '\n' ' ' | sed 's/  */ /g' | head -c 40 | sed 's/[[:space:]]*$//')
# Adicionar reticencias se truncou
if [[ ${#TOPIC} -ge 40 ]]; then
  TOPIC="${TOPIC:0:37}..."
fi

# Claudios: containers docker/podman ativos (worker + worker-fast)
WORKERS=0
BOCECHAS=0
WS="${WORKSPACE_DIR:-/workspace}"
_run_ps() {
  docker ps -q --filter "$1" 2>/dev/null | wc -l
}
_run_podman_ps() {
  podman ps -q --filter "$1" 2>/dev/null | wc -l
}
if command -v docker &>/dev/null; then
  [[ -S "/host/podman.sock" ]] && export DOCKER_HOST="unix:///host/podman.sock"
  W1=$(_run_ps "label=com.docker.compose.service=worker")
  W2=$(_run_ps "label=com.docker.compose.service=worker-fast")
  WORKERS=$(( W1 + W2 ))
  WORKERS=$(echo "$WORKERS" | tr -d '[:space:]')
fi
if [[ "$WORKERS" -eq 0 ]] && command -v podman &>/dev/null; then
  W1=$(_run_podman_ps "label=com.docker.compose.service=worker")
  W2=$(_run_podman_ps "label=com.docker.compose.service=worker-fast")
  WORKERS=$(( W1 + W2 ))
  WORKERS=$(echo "$WORKERS" | tr -d '[:space:]')
fi
if [[ "$WORKERS" -eq 0 ]] && [[ -d "$WS/.ephemeral/logs" ]]; then
  now_sec=$(date +%s)
  for log in "$WS"/.ephemeral/logs/worker-*.log; do
    [[ -f "$log" ]] || continue
    mod=$(stat -c %Y "$log" 2>/dev/null || echo 0)
    [[ $(( now_sec - mod )) -le 900 ]] && WORKERS=$(( WORKERS + 1 ))
  done
fi
# Bochechas: só conta pastas em running/ com .lock não expirado (evita órfão = sempre 1)
RUNNING_DIR="$WS/vault/_agent/tasks/running"
if [[ -d "$RUNNING_DIR" ]]; then
  now_epoch=$(date +%s)
  for dir in "$RUNNING_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/.lock" ]] || continue
    started=$(grep '^started=' "$dir/.lock" 2>/dev/null | cut -d= -f2)
    timeout=$(grep '^timeout=' "$dir/.lock" 2>/dev/null | cut -d= -f2)
    [[ -z "$started" || -z "$timeout" ]] && continue
    # started é ISO (2025-03-14T12:00:00Z); timeout é segundos
    start_epoch=$(date -d "$started" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s 2>/dev/null || echo 0)
    end_epoch=$(( start_epoch + timeout ))
    [[ $now_epoch -lt $end_epoch ]] && BOCECHAS=$(( BOCECHAS + 1 ))
  done
fi

# Repo: basename do workspace (ex: nixos, monolito)
REPO=""
if [[ -n "$WORKSPACE_DIR" ]]; then
  REPO=$(basename "$WORKSPACE_DIR")
fi

# Formatar tamanho de contexto (200000 -> 200k, 1000000 -> 1M)
fmt_tokens() {
  local n="${1:-0}"
  if [[ "$n" -ge 1000000 ]]; then
    echo "$(( n / 1000000 ))M"
  elif [[ "$n" -ge 1000 ]]; then
    echo "$(( n / 1000 ))k"
  else
    echo "$n"
  fi
}
CTX_SIZE_FMT=$(fmt_tokens "$CTX_SIZE")
CTX_USED_K=$(( CTX_USED / 1000 ))

# Minibarra (value, max, width) — sem ANSI; caracteres de bloco para status line
minibar() {
  local val="${1:-0}" max="${2:-100}" w="${3:-4}"
  [[ "$max" -le 0 ]] && max=1
  local fill=$(( val * w / max ))
  [[ $fill -gt $w ]] && fill=$w
  local i
  local s=""
  for (( i=0; i<fill; i++ )); do s="${s}█"; done
  for (( i=fill; i<w; i++ )); do s="${s}░"; done
  echo "$s"
}

# Três barras: contexto %, Claudios (docker), Bochechas (tasks em running/)
BAR_W=4
CTX_BAR=$(minibar "$CTX_PCT" 100 "$BAR_W")
CLAUDIOS_MAX=5
BOCECHAS_MAX=10
CLAUDIOS_BAR=$(minibar "$WORKERS" "$CLAUDIOS_MAX" "$BAR_W")
BOCECHAS_BAR=$(minibar "$BOCECHAS" "$BOCECHAS_MAX" "$BAR_W")

# Contexto: barra + usado em K / máx (ex: 123k/1M)
CTX_STR="ctx ${CTX_BAR} ${CTX_USED_K}k/${CTX_SIZE_FMT}"

# Duração da sessão: ms -> 0s, 1m, 1h 5m + barra (escala 0–1h)
DURATION_SEC=0
[[ -n "$COST_DURATION_MS" && "$COST_DURATION_MS" != "0" && "$COST_DURATION_MS" != "null" ]] && DURATION_SEC=$(( COST_DURATION_MS / 1000 ))
if [[ $DURATION_SEC -ge 3600 ]]; then
  h=$(( DURATION_SEC / 3600 ))
  m=$(( (DURATION_SEC % 3600) / 60 ))
  DURATION_STR="${h}h ${m}m"
elif [[ $DURATION_SEC -ge 60 ]]; then
  m=$(( DURATION_SEC / 60 ))
  DURATION_STR="${m}m"
else
  [[ "$DURATION_SEC" -eq 1 ]] && DURATION_STR="1 second" || DURATION_STR="${DURATION_SEC} seconds"
fi

# Linhas editadas
LINES_STR=""
if [[ -n "$LINES_ADDED" && -n "$LINES_REMOVED" ]] && { [[ "$LINES_ADDED" != "0" ]] || [[ "$LINES_REMOVED" != "0" ]]; }; then
  LINES_STR="+${LINES_ADDED} -${LINES_REMOVED}"
fi

# Cost: so exibe se > 0
COST_STR=""
if [[ -n "$COST_USD" && "$COST_USD" != "0" && "$COST_USD" != "null" ]]; then
  COST_STR=" | \$$(printf '%.2f' "$COST_USD")"
fi

# Worktree: so exibe se estiver em worktree
WT_STR=""
if [[ -n "$WORKTREE_NAME" && "$WORKTREE_NAME" != "null" ]]; then
  WT_STR=" | wt:$WORKTREE_NAME"
fi

# Claudios = containers docker; Bochechas = background workers rodando (tasks em running/)
WORKER_INFO=" | Claudios ${WORKERS} ${CLAUDIOS_BAR}  Bochechas ${BOCECHAS} ${BOCECHAS_BAR}"

# Partes opcionais: linhas (duração foi para a direita, antes do modelo)
EXTRA=""
[[ -n "$LINES_STR" ]] && EXTRA=" | ${LINES_STR}"

# Status line: métricas à esquerda; à direita "alive for Xs!" e modelo
ALIVE_STR="alive for ${DURATION_STR}!"
RIGHT="${CTX_STR}${COST_STR}${EXTRA}${WT_STR}${WORKER_INFO} | ${ALIVE_STR} | $MODEL"

# Terminal title via OSC (stderr)
printf '\033]0;Claude: %s\007' "$TOPIC" >&2

echo "$RIGHT"
