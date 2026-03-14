#!/bin/bash
# Statusline compacta (oneliner) com emojis
# Mostra: 🔌[session] | 🧠model | 📊ctx% | W:x R:y
# Output stdout: status line visivel
# Output stderr: terminal title (OSC)

input=$(cat)

# Extrair dados basicos
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')

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

# Worker info
WORKERS=0
RUNNING=0
if command -v docker &>/dev/null; then
  WORKERS=$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | wc -l || echo "0")
  WORKERS=$(echo "$WORKERS" | tr -d '[:space:]')
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

WORKER_SUFFIX=""
if [[ "$WORKERS" -gt 0 ]] || [[ "$RUNNING" -gt 0 ]]; then
  WORKER_SUFFIX=" | W:${WORKERS} R:${RUNNING}"
fi

# Compact oneliner
STATUSLINE="${SESSION_STR} | ${MODEL_EMOJI}${MODEL_SHORT} | 📊${CTX}%${WORKER_SUFFIX}"

# Terminal title
if [[ -n "$SESSION" ]]; then
  printf '\033]0;Claude[%s]: %s\007' "$SESSION" "$TOPIC" >&2
else
  printf '\033]0;Claude: %s\007' "$TOPIC" >&2
fi

echo "$STATUSLINE"
