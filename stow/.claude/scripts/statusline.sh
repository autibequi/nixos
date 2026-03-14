#!/bin/bash
# Status line com deteccao automatica de topico via ultima msg do user
# Output stdout: status line visivel
# Output stderr: terminal title (OSC) pro Hyprland/waybar

input=$(cat)

# Extrair dados basicos
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')

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

# Worker info: contar workers ativos e tasks rodando
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

# Session name (via env var, propagada pelo docker-compose)
SESSION="${CLAUDE_SESSION:-}"

# Worker suffix
WORKER_INFO=""
if [[ "$WORKERS" -gt 0 ]] || [[ "$RUNNING" -gt 0 ]]; then
  WORKER_INFO=" | W:${WORKERS} R:${RUNNING}"
fi

# Terminal title via OSC (stderr → Hyprland pega) + Status line (stdout)
if [[ -n "$SESSION" ]]; then
  printf '\033]0;Claude[%s]: %s\007' "$SESSION" "$TOPIC" >&2
  echo "\033[36m[$SESSION]\033[0m $TOPIC | $MODEL ${CTX}%%${WORKER_INFO}"
else
  printf '\033]0;Claude: %s\007' "$TOPIC" >&2
  echo "\033[36m$TOPIC\033[0m | $MODEL ${CTX}%%${WORKER_INFO}"
fi
