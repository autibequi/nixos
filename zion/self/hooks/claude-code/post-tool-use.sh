#!/usr/bin/env bash
# Hook: PostToolUse
_ZION_FILE="${HOME:-/home/claude}/.zion"; [ -f "$_ZION_FILE" ] || _ZION_FILE="/.zion"
[ -f "$_ZION_FILE" ] && { set -a; source "$_ZION_FILE" 2>/dev/null || true; set +a; }

# Hook: PostToolUse — monitoramento de contexto
# stdout → system-reminder (Claude vê)

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

read -r TOKENS_USED TOKENS_MAX < <(echo "$INPUT" | jq -r '[.context_tokens_used // empty, .context_window_size // empty] | @tsv' 2>/dev/null)

[ -z "$TOKENS_USED" ] || [ -z "$TOKENS_MAX" ] || [ "$TOKENS_MAX" -eq 0 ] && exit 0

REMAINING_PCT=$(( (TOKENS_MAX - TOKENS_USED) * 100 / TOKENS_MAX ))
DEBOUNCE="/tmp/.zion-context-warn"

if [ "$REMAINING_PCT" -le 25 ]; then
  echo "⚠️ CONTEXTO CRÍTICO: ${REMAINING_PCT}% restante (${TOKENS_USED}/${TOKENS_MAX} tokens). ENCERRE a tarefa atual, faça commit e inicie nova sessão."
elif [ "$REMAINING_PCT" -le 35 ]; then
  LAST=$(cat "$DEBOUNCE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [ $(( NOW - LAST )) -gt 300 ]; then
    echo "⚠️ CONTEXTO BAIXO: ${REMAINING_PCT}% restante. Evite iniciar tarefas novas grandes."
    echo "$NOW" > "$DEBOUNCE"
  fi
else
  rm -f "$DEBOUNCE" 2>/dev/null || true
fi
