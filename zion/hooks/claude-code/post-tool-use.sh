#!/usr/bin/env bash
# Hook: PostToolUse — remove bongo signal + monitoramento de contexto

# Remove sinal do hive-mind → claude-typer para os keypresses
rm -f "/workspace/.hive-mind/bongo-active" 2>/dev/null || true

# Monitoramento de contexto — avisa quando está baixo
# stdout → system-reminder (Claude vê); stderr → terminal do user
INPUT=$(cat 2>/dev/null)
if [ -n "$INPUT" ]; then
  TOKENS_USED=$(echo "$INPUT" | jq -r '.context_tokens_used // empty' 2>/dev/null)
  TOKENS_MAX=$(echo "$INPUT" | jq -r '.context_window_size // empty' 2>/dev/null)

  if [ -n "$TOKENS_USED" ] && [ -n "$TOKENS_MAX" ] && [ "$TOKENS_MAX" -gt 0 ]; then
    REMAINING_PCT=$(( (TOKENS_MAX - TOKENS_USED) * 100 / TOKENS_MAX ))
    DEBOUNCE="/tmp/.zion-context-warn"

    if [ "$REMAINING_PCT" -le 25 ]; then
      # Crítico: sempre avisar, sem debounce
      echo "⚠️ CONTEXTO CRÍTICO: ${REMAINING_PCT}% restante (${TOKENS_USED}/${TOKENS_MAX} tokens). ENCERRE a tarefa atual, faça commit e inicie nova sessão."
    elif [ "$REMAINING_PCT" -le 35 ]; then
      # Baixo: debounce de 5 minutos para não spammar
      LAST=$(cat "$DEBOUNCE" 2>/dev/null || echo 0)
      NOW=$(date +%s)
      if [ $(( NOW - LAST )) -gt 300 ]; then
        echo "⚠️ CONTEXTO BAIXO: ${REMAINING_PCT}% restante. Evite iniciar tarefas novas grandes — priorize concluir o que está em andamento."
        echo "$NOW" > "$DEBOUNCE"
      fi
    else
      # Contexto ok — resetar debounce
      rm -f "$DEBOUNCE" 2>/dev/null || true
    fi
  fi
fi
