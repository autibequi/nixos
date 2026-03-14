#!/bin/bash
# Statusline compacta (oneliner) com emojis
# Mostra: 🔌[session] | 🧠model | 📊ctx% | W:x R:y
# Output stdout: status line visivel
# Output stderr: terminal title (OSC)

input=$(cat)

# Extrair dados basicos
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
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
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
CTX_USED_K=$(( CTX_USED / 1000 ))
# Size: 1000000 -> 1M, 200000 -> 200k
if [[ "$CTX_SIZE" -ge 1000000 ]]; then CTX_SIZE_FMT="$(( CTX_SIZE / 1000000 ))M"
elif [[ "$CTX_SIZE" -ge 1000 ]]; then CTX_SIZE_FMT="$(( CTX_SIZE / 1000 ))k"
else CTX_SIZE_FMT="0"; fi
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')

# Minibarra (value, max, width) — sem ANSI
minibar() {
  local val="${1:-0}" max="${2:-100}" w="${3:-4}"
  [[ "$max" -le 0 ]] && max=1
  local fill=$(( val * w / max ))
  [[ $fill -gt $w ]] && fill=$w
  local i s=""
  for (( i=0; i<fill; i++ )); do s="${s}█"; done
  for (( i=fill; i<w; i++ )); do s="${s}░"; done
  echo "$s"
}

# Extrair topico da ultima mensagem do user no transcript
TOPIC=""
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
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

# Fallback
if [[ -z "$TOPIC" || "$TOPIC" == "null" ]]; then
  TOPIC="nova sessao"
fi

# Limpar e truncar topico (~30 chars pra deixar espaço)
TOPIC=$(echo "$TOPIC" | tr '\n' ' ' | sed 's/  */ /g' | head -c 30 | sed 's/[[:space:]]*$//')
if [[ ${#TOPIC} -ge 30 ]]; then
  TOPIC="${TOPIC:0:27}..."
fi

# Claudios: worker + worker-fast; fallback por logs
WORKERS=0
RUNNING=0
WORKSPACE_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
_docker_ps() {
  [[ -S "/host/podman.sock" ]] && DOCKER_HOST="unix:///host/podman.sock" docker ps "$@" 2>/dev/null || docker ps "$@" 2>/dev/null || true
}
if command -v docker &>/dev/null; then
  W1=$(_docker_ps -q --filter "label=com.docker.compose.service=worker" 2>/dev/null | wc -l)
  W2=$(_docker_ps -q --filter "label=com.docker.compose.service=worker-fast" 2>/dev/null | wc -l)
  WORKERS=$(( W1 + W2 ))
  WORKERS=$(echo "$WORKERS" | tr -d '[:space:]')
fi
WS="${WORKSPACE_DIR:-/workspace}"
if [[ "$WORKERS" -eq 0 ]] && [[ -d "$WS/.ephemeral/logs" ]]; then
  now_sec=$(date +%s)
  for log in "$WS"/.ephemeral/logs/worker-*.log; do
    [[ -f "$log" ]] || continue
    mod=$(stat -c %Y "$log" 2>/dev/null || echo 0)
    [[ $(( now_sec - mod )) -le 900 ]] && WORKERS=$(( WORKERS + 1 ))
  done
fi
KANBAN="/workspace/vault/kanban.md"
if [[ -f "$KANBAN" ]]; then
  in_col=0
  while IFS= read -r line; do
    if [[ "$line" == "## Em Andamento" ]]; then in_col=1; continue; fi
    if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
    if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then RUNNING=$((RUNNING + 1)); fi
  done < "$KANBAN"
fi

# Session name
SESSION="${CLAUDE_SESSION:-}"

# Format compact: 🔌[session] | 🧠model | 📊ctx% | W:x R:y
SESSION_STR=""
if [[ -n "$SESSION" ]]; then
  SESSION_STR="🔌[$SESSION]"
else
  SESSION_STR="🔌[~]"
fi

# Parse model name (shorthand: "Opus 4.6..." → "opus")
MODEL_SHORT=$(echo "$MODEL" | grep -oE "^[a-zA-Z]+" | tr '[:upper:]' '[:lower:]' | head -c 3)
MODEL_EMOJI="🧠"

# Tres barras: contexto %, Claudios (workers), Bochechas (agentes em background)
CTX_BAR=$(minibar "$CTX" 100 4)
CLAUDIOS_BAR=$(minibar "$WORKERS" 5 4)
BOCECHAS_BAR=$(minibar "$RUNNING" 10 4)

# Compact oneliner: barras à esquerda, modelo na extrema direita
STATUSLINE="${SESSION_STR} | ctx ${CTX_BAR} ${CTX_USED_K}k/${CTX_SIZE_FMT} | Claudios [${WORKERS}] ${CLAUDIOS_BAR}  Bochechas [${RUNNING}] ${BOCECHAS_BAR} | ${MODEL_EMOJI}${MODEL_SHORT}"

# Terminal title
if [[ -n "$SESSION" ]]; then
  printf '\033]0;Claude[%s]: %s\007' "$SESSION" "$TOPIC" >&2
else
  printf '\033]0;Claude: %s\007' "$TOPIC" >&2
fi

echo "$STATUSLINE"
