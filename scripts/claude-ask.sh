#!/usr/bin/env bash
# claude-ask.sh — Abre Alacritty com Claude respondendo a um prompt
# Uso: claude-ask.sh "minha pergunta"
#      claude-ask.sh (sem args = abre interativo)
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/nixos}"
COMPOSE="podman-compose -f $PROJECT_DIR/zion/cli/docker-compose.claude.yml"
LOCKFILE="/tmp/claude-ask.lock"
PROMPT="${1:-}"

# Guard: se já tá rodando, não abre outro
if [ -f "$LOCKFILE" ]; then
  pid=$(cat "$LOCKFILE" 2>/dev/null || echo "")
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "[claude-ask] Já rodando (PID $pid) — focando janela existente"
    hyprctl dispatch focuswindow "title:claude-ask" 2>/dev/null || true
    exit 0
  fi
  rm -f "$LOCKFILE"
fi

# Registra PID
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

cd "$PROJECT_DIR"

# Garante sandbox rodando
$COMPOSE up -d sandbox 2>/dev/null

if [ -n "$PROMPT" ]; then
  # One-shot: responde e espera Enter pra fechar
  $COMPOSE exec sandbox claude --permission-mode bypassPermissions -p "$PROMPT"
  echo ""
  echo "─── Pressione Enter pra fechar ───"
  read -r
else
  # Interativo: abre Claude normal
  $COMPOSE exec sandbox claude --permission-mode bypassPermissions
fi
