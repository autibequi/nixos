#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
TIMEOUT="${1:-600}"
LOCKFILE="$TASKS/.runner.lock"

# ── Global lock: impede execuções simultâneas ─────────────────────
if [ -f "$LOCKFILE" ]; then
  runner_pid=$(cat "$LOCKFILE" 2>/dev/null || echo "")
  if [ -n "$runner_pid" ] && kill -0 "$runner_pid" 2>/dev/null; then
    echo "[clau] Outra instância rodando (pid $runner_pid). Saindo." >&2
    exit 0
  fi
  echo "[clau] Lock stale (pid $runner_pid morto). Removendo." >&2
  rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"

# ── Trap: devolve task pra origem se interrompido ─────────────────
cleanup() {
  local sig="${1:-EXIT}"
  if [ -n "${RUNNING_TASK:-}" ] && [ -d "$TASKS/running/$RUNNING_TASK" ]; then
    rm -f "$TASKS/running/$RUNNING_TASK/.lock"
    if [ "${IS_RECURRING:-}" = "1" ]; then
      mv "$TASKS/running/$RUNNING_TASK" "$TASKS/recurring/$RUNNING_TASK"
      echo "[clau] $sig — '$RUNNING_TASK' devolvida pra recurring/"
    else
      mv "$TASKS/running/$RUNNING_TASK" "$TASKS/pending/$RUNNING_TASK"
      echo "[clau] $sig — '$RUNNING_TASK' devolvida pra pending/"
    fi
  fi
  rm -f "$LOCKFILE"
}
trap 'cleanup SIGINT; exit 1' SIGINT
trap 'cleanup SIGTERM; exit 1' SIGTERM
trap 'cleanup EXIT' EXIT

# ── 1) Reap stuck tasks ──────────────────────────────────────────
# First: reap orphaned tasks (in running/ but no lock file)
for dir in "$TASKS/running"/*/; do
  [ -d "$dir" ] || continue
  [ -f "$dir/.lock" ] && continue
  name=$(basename "$dir")
  echo "[clau] Orphan — '$name' sem lock, devolvendo pra pending/"
  mv "$dir" "$TASKS/pending/$name" 2>/dev/null || rm -rf "$dir"
done

# Then: reap locked tasks with dead PIDs or expired timeouts
for lock in "$TASKS/running"/*/.lock; do
  [ -f "$lock" ] || continue
  task_pid=$(grep '^pid=' "$lock" | cut -d= -f2)
  started=$(grep '^started=' "$lock" | cut -d= -f2)
  source=$(grep '^source=' "$lock" | cut -d= -f2 || echo "pending")
  task=$(dirname "$lock")
  name=$(basename "$task")
  elapsed=$(( $(date +%s) - $(date -d "$started" +%s) ))

  # Reap se: PID morto OU timeout estourado
  should_reap=0
  if [ -n "$task_pid" ] && ! kill -0 "$task_pid" 2>/dev/null; then
    echo "[clau] PID $task_pid morto — reaping '$name'"
    should_reap=1
  elif [ "$elapsed" -gt $(( TIMEOUT + 300 )) ]; then
    echo "[clau] Timeout ${elapsed}s — reaping '$name'"
    should_reap=1
  fi

  if [ "$should_reap" = "1" ]; then
    rm -f "$task/.lock"
    if [ "$source" = "recurring" ]; then
      mv "$task" "$TASKS/recurring/$name"
      echo "[clau] '$name' devolvida pra recurring/"
    else
      mv "$task" "$TASKS/pending/$name"
      echo "[clau] '$name' devolvida pra pending/ (retry)"
    fi
  fi
done

# ── 2) Pick task: pending first, then recurring ──────────────────
TASK=""
IS_RECURRING=""
SOURCE_DIR=""

# Pending (one-shot) tem prioridade
TASK=$(ls -1 "$TASKS/pending/" 2>/dev/null | grep -v '\.gitkeep' | sort | head -1 || true)
if [ -n "$TASK" ]; then
  IS_RECURRING="0"
  SOURCE_DIR="pending"
fi

# Se não tem pending, pega recurring (round-robin por último executado)
if [ -z "$TASK" ]; then
  # Pega a recurring que foi executada há mais tempo (ou nunca)
  OLDEST_TIME=99999999999
  for dir in "$TASKS/recurring"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    ctx="$EPHEMERAL/notes/$name/historico.log"
    if [ -f "$ctx" ]; then
      last_ts=$(tail -1 "$ctx" | cut -d'|' -f1 | xargs)
      last_epoch=$(date -d "$last_ts" +%s 2>/dev/null || echo "0")
    else
      last_epoch=0
    fi
    if [ "$last_epoch" -lt "$OLDEST_TIME" ]; then
      OLDEST_TIME=$last_epoch
      TASK=$name
    fi
  done
  if [ -n "$TASK" ]; then
    IS_RECURRING="1"
    SOURCE_DIR="recurring"
  fi
fi

[ -z "${TASK:-}" ] && echo "Sem tarefas pendentes ou recorrentes." && exit 0

# Skip if task is already in running (previous run died mid-execution)
if [ -d "$TASKS/running/$TASK" ]; then
  echo "[clau] '$TASK' já está em running/ (run anterior não fez cleanup). Limpando..."
  rm -f "$TASKS/running/$TASK/.lock"
  if [ "$IS_RECURRING" = "1" ]; then
    rm -rf "$TASKS/running/$TASK"
  else
    rm -rf "$TASKS/running/$TASK"
  fi
fi

RUNNING_TASK="$TASK"

# ── 3) Move to running + lock ────────────────────────────────────
mv "$TASKS/$SOURCE_DIR/$TASK" "$TASKS/running/$TASK"
cat > "$TASKS/running/$TASK/.lock" <<EOF
pid=$$
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$TIMEOUT
source=$SOURCE_DIR
EOF

# ── 4) Prepare context ───────────────────────────────────────────
INSTRUCTIONS=$(cat "$TASKS/running/$TASK/CLAUDE.md")
CONTEXT_DIR="$EPHEMERAL/notes/$TASK"
mkdir -p "$CONTEXT_DIR"

CONTEXT=""
if [ -f "$CONTEXT_DIR/contexto.md" ]; then
  CONTEXT="

## Contexto da execução anterior
$(cat "$CONTEXT_DIR/contexto.md")"
fi

HISTORICO=""
if [ -f "$CONTEXT_DIR/historico.log" ]; then
  HISTORICO="

## Histórico de execuções (últimas 20)
$(tail -20 "$CONTEXT_DIR/historico.log")"
fi

RECURRING_MSG=""
if [ "$IS_RECURRING" = "1" ]; then
  RECURRING_MSG="

## IMPORTANTE: Task recorrente (imortal)
- Você roda a cada ~1 hora. Seu timeout é ${TIMEOUT}s (~10min).
- Salve seu estado em: $CONTEXT_DIR/contexto.md (será lido na próxima execução)
- Use $CONTEXT_DIR/ para qualquer arquivo auxiliar que precise persistir
- Não tente fazer tudo de uma vez — priorize, execute o mais importante, salve progresso
- SEMPRE atualize contexto.md no final com: o que fez, o que falta, próximos passos"
fi

START=$SECONDS

# ── 5) Execute ────────────────────────────────────────────────────
if timeout "$TIMEOUT" claude --permission-mode bypassPermissions \
  -p "Modo autônomo. Tarefa: $TASK
Diretório da tarefa: $TASKS/running/$TASK
Diretório de contexto: $CONTEXT_DIR
Hora atual: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Tipo: $([ "$IS_RECURRING" = "1" ] && echo "RECORRENTE (imortal)" || echo "ONE-SHOT")

$INSTRUCTIONS
$RECURRING_MSG
$CONTEXT
$HISTORICO

Ao terminar, resuma em uma linha." 2>&1; then
  STATUS="ok"
else
  STATUS="fail:$?"
fi

DURATION=$((SECONDS - START))

# ── 6) Route result ──────────────────────────────────────────────
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $STATUS | ${DURATION}s" >> "$CONTEXT_DIR/historico.log"

if [ "$IS_RECURRING" = "1" ]; then
  # Recorrente: volta pra recurring/
  rm -f "$TASKS/running/$TASK/.lock"
  mv "$TASKS/running/$TASK" "$TASKS/recurring/$TASK"
  echo "[clau] Recorrente '$TASK' devolvida → recurring/"
else
  # One-shot: move pra done/failed
  rm -f "$TASKS/running/$TASK/.lock"
  if [ "$STATUS" = "ok" ]; then
    mv "$TASKS/running/$TASK" "$TASKS/done/$TASK"
    echo "$STATUS: ${DURATION}s" > "$TASKS/done/$TASK/.result"
  else
    mv "$TASKS/running/$TASK" "$TASKS/failed/$TASK"
    echo "$STATUS: ${DURATION}s" > "$TASKS/failed/$TASK/.result"
  fi
fi

RUNNING_TASK=""

# ── 7) Log usage ─────────────────────────────────────────────────
mkdir -p "$EPHEMERAL/usage"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"task\":\"$TASK\",\"duration\":$DURATION,\"status\":\"$STATUS\",\"type\":\"$([ "$IS_RECURRING" = "1" ] && echo "recurring" || echo "oneshot")\"}" \
  >> "$EPHEMERAL/usage/$(date +%Y-%m).jsonl"
