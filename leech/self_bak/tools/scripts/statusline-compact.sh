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

WORKERS=0
WORKSPACE_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
WS="${WORKSPACE_DIR:-/workspace}"
if [[ -d "$WS/.ephemeral/agents" ]]; then
  now_sec=$(date +%s)
    [[ "$dir" == *"*"* ]] && continue
    [[ -d "$dir" && -f "$dir/.live" ]] || continue
    mod=$(stat -c %Y "$dir/.live" 2>/dev/null || echo 0)
    [[ $(( now_sec - mod )) -le 900 ]] && WORKERS=$(( WORKERS + 1 ))
  done
fi
# Usage no período (lê .ephemeral/usage-bar.txt gerado por usage-bar.sh)
USAGE_PCT=0
USAGE_PERIOD=""
if [[ -f "$WS/.ephemeral/usage-bar.txt" ]]; then
  line1=$(head -1 "$WS/.ephemeral/usage-bar.txt" 2>/dev/null)
  USAGE_PCT=$(echo "$line1" | sed -n 's/.*pct=\([0-9]*\).*/\1/p')
  USAGE_PERIOD=$(echo "$line1" | sed -n 's/.*period=\([^ ]*\).*/\1/p')
  [[ -z "$USAGE_PCT" || ! "$USAGE_PCT" =~ ^[0-9]+$ ]] && USAGE_PCT=0
fi
USAGE_BAR=$(minibar "${USAGE_PCT:-0}" 100 4)

# Parse model name (shorthand: "Opus 4.6..." → "opus")
MODEL_SHORT=$(echo "$MODEL" | grep -oE "^[a-zA-Z]+" | tr '[:upper:]' '[:lower:]' | head -c 3)
MODEL_EMOJI="🧠"

# Barras: contexto %, Claudios, usage (período)
CTX_BAR=$(minibar "$CTX" 100 4)
CLAUDIOS_BAR=$(minibar "$WORKERS" 5 4)

# Compact oneliner: ctx | Claudios | usage (período) | modelo
STATUSLINE="ctx ${CTX_BAR} ${CTX_USED_K}k/${CTX_SIZE_FMT} | Claudios ${WORKERS} ${CLAUDIOS_BAR} | use ${USAGE_BAR} ${USAGE_PCT}%${USAGE_PERIOD:+ ${USAGE_PERIOD}} | ${MODEL_EMOJI}${MODEL_SHORT}"

# Terminal title
printf '\033]0;Claude: %s\007' "$TOPIC" >&2

echo "$STATUSLINE"
