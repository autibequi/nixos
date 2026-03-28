#!/usr/bin/env bash
# Hook: PostToolUse — aviso de contexto (Claude: texto | Cursor/OPENCODE: JSON additional_context)
# ENGINE: CLAUDE | CURSOR | OPENCODE

export ENGINE="${ENGINE:-CLAUDE}"

_LEECH_FILE="${HOME:-/home/claude}/.leech"
[ -f "$_LEECH_FILE" ] || _LEECH_FILE="/.leech"
[ -f "$_LEECH_FILE" ] && { set -a; source "$_LEECH_FILE" 2>/dev/null || true; set +a; }
export ENGINE="${ENGINE:-CLAUDE}"

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && { [ "$ENGINE" != "CLAUDE" ] && echo '{}' || true; exit 0; }

TOKENS_USED=$(echo "$INPUT" | jq -r '.context_tokens_used // .context.tokens_used // empty' 2>/dev/null || true)
TOKENS_MAX=$(echo "$INPUT" | jq -r '.context_window_size // .context_window // .context.max_tokens // empty' 2>/dev/null || true)

if ! [[ "$TOKENS_USED" =~ ^[0-9]+$ ]] || ! [[ "$TOKENS_MAX" =~ ^[0-9]+$ ]] || [ "$TOKENS_MAX" -eq 0 ]; then
  [ "$ENGINE" != "CLAUDE" ] && echo '{}'
  exit 0
fi

REMAINING_PCT=$(( (TOKENS_MAX - TOKENS_USED) * 100 / TOKENS_MAX ))
DEBOUNCE="/tmp/.leech-context-warn-${ENGINE:-CLAUDE}"
WARN=""

if [ "$REMAINING_PCT" -le 25 ]; then
  WARN="⚠️ CONTEXTO CRÍTICO: ${REMAINING_PCT}% restante (${TOKENS_USED}/${TOKENS_MAX} tokens). ENCERRE a tarefa atual, faça commit e inicie nova sessão."
elif [ "$REMAINING_PCT" -le 35 ]; then
  LAST=$(cat "$DEBOUNCE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  if [ $(( NOW - LAST )) -gt 300 ]; then
    WARN="⚠️ CONTEXTO BAIXO: ${REMAINING_PCT}% restante. Evite iniciar tarefas novas grandes."
    echo "$NOW" > "$DEBOUNCE"
  fi
else
  rm -f "$DEBOUNCE" 2>/dev/null || true
fi

if [ -z "$WARN" ]; then
  [ "$ENGINE" != "CLAUDE" ] && echo '{}'
  exit 0
fi

case "$ENGINE" in
  CURSOR|OPENCODE)
    printf '%s' "$WARN" | python3 -c 'import json,sys; print(json.dumps({"additional_context": sys.stdin.read()}))' 2>/dev/null || echo '{}'
    ;;
  *)
    echo "$WARN"
    ;;
esac
