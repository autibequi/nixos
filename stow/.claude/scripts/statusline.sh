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
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // ""')
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
WORKSPACE_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
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

# Session: JSON session_id (curto) ou env CLAUDE_SESSION
SESSION="${CLAUDE_SESSION:-}"
if [[ -z "$SESSION" && -n "$SESSION_ID" ]]; then
  SESSION="${SESSION_ID:0:8}"
fi

# Repo: basename do workspace (ex: nixos, monolito)
REPO=""
if [[ -n "$WORKSPACE_DIR" ]]; then
  REPO=$(basename "$WORKSPACE_DIR")
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

# Worker suffix
WORKER_INFO=""
if [[ "$WORKERS" -gt 0 ]] || [[ "$RUNNING" -gt 0 ]]; then
  WORKER_INFO=" | W:${WORKERS} R:${RUNNING}"
fi

# Monta a linha: [repo] [session] topic | Model ctx% | $cost | wt:name | W:x R:y
LEFT=""
[[ -n "$REPO" ]] && LEFT="${LEFT}[$REPO] "
[[ -n "$SESSION" ]] && LEFT="${LEFT}[$SESSION] "
LEFT="${LEFT}$TOPIC"
RIGHT="$MODEL ${CTX}%${COST_STR}${WT_STR}${WORKER_INFO}"

# Terminal title via OSC (stderr)
if [[ -n "$SESSION" ]]; then
  printf '\033]0;Claude[%s]: %s\007' "$SESSION" "$TOPIC" >&2
else
  printf '\033]0;Claude: %s\007' "$TOPIC" >&2
fi

echo "${LEFT} | ${RIGHT}"
