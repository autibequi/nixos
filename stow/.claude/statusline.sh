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

# Terminal title via OSC (stderr → Hyprland pega)
printf '\033]0;Claude: %s\007' "$TOPIC" >&2

# Status line (stdout)
echo "\033[36m$TOPIC\033[0m | $MODEL ${CTX}%%"
