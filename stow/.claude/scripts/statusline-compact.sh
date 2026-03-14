#!/bin/bash
# Statusline compacta (oneliner) com emojis
# Mostra: ctx | Claudios | Bochechas | modelo
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

# Claudios: só .agents/bochecha_* com .live recente (sem fallback para não travar em 1)
WORKERS=0
BOCECHAS=0
WORKSPACE_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
WS="${WORKSPACE_DIR:-/workspace}"
if [[ -d "$WS/.agents" ]]; then
  now_sec=$(date +%s)
  for dir in "$WS/.agents"/bochecha_*/; do
    [[ "$dir" == *"*"* ]] && continue
    [[ -d "$dir" && -f "$dir/.live" ]] || continue
    mod=$(stat -c %Y "$dir/.live" 2>/dev/null || echo 0)
    [[ $(( now_sec - mod )) -le 900 ]] && WORKERS=$(( WORKERS + 1 ))
  done
fi
RUNNING_DIR="$WS/vault/_agent/tasks/running"
if [[ -d "$RUNNING_DIR" ]]; then
  now_epoch=$(date +%s)
  for dir in "$RUNNING_DIR"/*/; do
    [[ "$dir" == *"*"* ]] && continue
    [[ -d "$dir" && -f "$dir/.lock" ]] || continue
    started=$(grep '^started=' "$dir/.lock" 2>/dev/null | cut -d= -f2)
    timeout=$(grep '^timeout=' "$dir/.lock" 2>/dev/null | cut -d= -f2)
    [[ -z "$started" || -z "$timeout" ]] && continue
    start_epoch=$(date -d "$started" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s 2>/dev/null || echo 0)
    [[ -z "$start_epoch" || "$start_epoch" -eq 0 ]] && continue
    end_epoch=$(( start_epoch + timeout ))
    [[ $now_epoch -lt $end_epoch ]] && BOCECHAS=$(( BOCECHAS + 1 ))
  done
fi

# Session name
# Parse model name (shorthand: "Opus 4.6..." → "opus")
MODEL_SHORT=$(echo "$MODEL" | grep -oE "^[a-zA-Z]+" | tr '[:upper:]' '[:lower:]' | head -c 3)
MODEL_EMOJI="🧠"

# Três barras: contexto %, Claudios (docker), Bochechas (running/)
CTX_BAR=$(minibar "$CTX" 100 4)
CLAUDIOS_BAR=$(minibar "$WORKERS" 5 4)
BOCECHAS_BAR=$(minibar "$BOCECHAS" 10 4)

# Compact oneliner: barras à esquerda, modelo na extrema direita
STATUSLINE="ctx ${CTX_BAR} ${CTX_USED_K}k/${CTX_SIZE_FMT} | Claudios ${WORKERS} ${CLAUDIOS_BAR}  Bochechas ${BOCECHAS} ${BOCECHAS_BAR} | ${MODEL_EMOJI}${MODEL_SHORT}"

# Terminal title
printf '\033]0;Claude: %s\007' "$TOPIC" >&2

echo "$STATUSLINE"
