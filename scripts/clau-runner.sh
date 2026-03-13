#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
LOCKFILE="$EPHEMERAL/.clau.lock"
TIMEOUT="${CLAU_TIMEOUT:-600}"
SPECIFIC_TASK="${1:-}"
MAX_TASKS="${CLAU_MAX_TASKS:-20}"

mkdir -p "$EPHEMERAL" "$TASKS/running" "$TASKS/done" "$TASKS/failed"

# ── Singleton via flock ──────────────────────────────────────────
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  echo "[clau] Outro worker já rodando. Singleton ativo — saindo."
  exit 0
fi
echo "[clau] Lock adquirido (PID $$)"

# ── Trap: cleanup ao sair ────────────────────────────────────────
cleanup() {
  local sig="${1:-EXIT}"
  if [ -n "${RUNNING_TASK:-}" ] && [ -d "$TASKS/running/$RUNNING_TASK" ]; then
    rm -f "$TASKS/running/$RUNNING_TASK/.lock"
    if [ "${CURRENT_SOURCE:-pending}" = "recurring" ]; then
      mv "$TASKS/running/$RUNNING_TASK" "$TASKS/recurring/$RUNNING_TASK" 2>/dev/null || true
      echo "[clau] $sig — '$RUNNING_TASK' devolvida pra recurring/"
    else
      mv "$TASKS/running/$RUNNING_TASK" "$TASKS/pending/$RUNNING_TASK" 2>/dev/null || true
      echo "[clau] $sig — '$RUNNING_TASK' devolvida pra pending/"
    fi
    RUNNING_TASK=""
  fi
}
trap 'cleanup SIGINT; exit 1' SIGINT
trap 'cleanup SIGTERM; exit 1' SIGTERM
trap 'cleanup EXIT' EXIT

# ── Reap tasks órfãs em running/ ────────────────────────────────
for dir in "$TASKS/running"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ -f "$dir/.lock" ]; then
    started=$(grep '^started=' "$dir/.lock" | cut -d= -f2)
    source=$(grep '^source=' "$dir/.lock" | cut -d= -f2 || echo "pending")
    elapsed=$(( $(date +%s) - $(date -d "$started" +%s 2>/dev/null || echo "0") ))
    # Se passou mais de timeout + 5min de grace, é órfã
    if [ "$elapsed" -le $(( TIMEOUT + 300 )) ]; then
      echo "[clau] '$name' ainda dentro do timeout (${elapsed}s) — skip reap"
      continue
    fi
    echo "[clau] Timeout ${elapsed}s — reaping '$name'"
  else
    source="pending"
    echo "[clau] Órfã sem lock — reaping '$name'"
  fi
  rm -f "$dir/.lock"
  if [ "$source" = "recurring" ]; then
    mv "$dir" "$TASKS/recurring/$name" 2>/dev/null || rm -rf "$dir"
    echo "[clau] '$name' → recurring/"
  else
    mv "$dir" "$TASKS/pending/$name" 2>/dev/null || rm -rf "$dir"
    echo "[clau] '$name' → pending/"
  fi
done

# ── Executa uma task ─────────────────────────────────────────────
run_task() {
  local task="$1" source_dir="$2" is_recurring="$3"

  # Validar CLAUDE.md
  if [ ! -f "$TASKS/$source_dir/$task/CLAUDE.md" ]; then
    echo "[clau] '$task' sem CLAUDE.md — skip"
    return 0
  fi

  # Claim via mv atômico
  if [ -d "$TASKS/running/$task" ]; then
    echo "[clau] '$task' já em running/ — skip"
    return 0
  fi
  if ! mv "$TASKS/$source_dir/$task" "$TASKS/running/$task" 2>/dev/null; then
    echo "[clau] '$task' sumiu (race condition?) — skip"
    return 0
  fi

  RUNNING_TASK="$task"
  CURRENT_SOURCE="$source_dir"

  cat > "$TASKS/running/$task/.lock" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$TIMEOUT
source=$source_dir
pid=$$
EOF

  echo "[clau] ▶ Executando '$task' (${source_dir}, timeout=${TIMEOUT}s)"

  # Preparar contexto
  local instructions context_dir context historico recurring_msg
  instructions=$(cat "$TASKS/running/$task/CLAUDE.md")
  context_dir="$EPHEMERAL/notes/$task"
  mkdir -p "$context_dir"

  context=""
  [ -f "$context_dir/contexto.md" ] && context="
## Contexto da execução anterior
$(cat "$context_dir/contexto.md")"

  historico=""
  [ -f "$context_dir/historico.log" ] && historico="
## Histórico de execuções (últimas 20)
$(tail -20 "$context_dir/historico.log")"

  recurring_msg=""
  if [ "$is_recurring" = "1" ]; then
    recurring_msg="
## IMPORTANTE: Task recorrente (imortal)
- Você roda a cada ~1 hora. Seu timeout é ${TIMEOUT}s (~10min).
- Salve seu estado em: $context_dir/contexto.md
- Use $context_dir/ para arquivos auxiliares
- Não tente fazer tudo de uma vez — priorize, execute o mais importante, salve progresso
- SEMPRE atualize contexto.md no final"
  fi

  local start_time=$SECONDS status

  if timeout "$TIMEOUT" claude --permission-mode bypassPermissions \
    -p "Modo autônomo. Tarefa: $task
Diretório da tarefa: $TASKS/running/$task
Diretório de contexto: $context_dir
Hora atual: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Tipo: $([ "$is_recurring" = "1" ] && echo "RECORRENTE (imortal)" || echo "ONE-SHOT")

$instructions
$recurring_msg
$context
$historico

Ao terminar, resuma em uma linha." 2>&1; then
    status="ok"
  else
    status="fail:$?"
  fi

  local duration=$((SECONDS - start_time))
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $status | ${duration}s" >> "$context_dir/historico.log"

  # Route resultado
  rm -f "$TASKS/running/$task/.lock"
  if [ "$is_recurring" = "1" ]; then
    mv "$TASKS/running/$task" "$TASKS/recurring/$task"
    echo "[clau] ✓ '$task' (${duration}s, $status) → recurring/"
  elif [ "$status" = "ok" ]; then
    mv "$TASKS/running/$task" "$TASKS/done/$task"
    echo "$status: ${duration}s" > "$TASKS/done/$task/.result"
    echo "[clau] ✓ '$task' (${duration}s) → done/"
  else
    mv "$TASKS/running/$task" "$TASKS/failed/$task"
    echo "$status: ${duration}s" > "$TASKS/failed/$task/.result"
    echo "[clau] ✗ '$task' (${duration}s, $status) → failed/"
  fi

  RUNNING_TASK=""
  CURRENT_SOURCE=""

  # Log usage
  mkdir -p "$EPHEMERAL/usage"
  echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"task\":\"$task\",\"duration\":$duration,\"status\":\"$status\",\"type\":\"$([ "$is_recurring" = "1" ] && echo "recurring" || echo "oneshot")\"}" \
    >> "$EPHEMERAL/usage/$(date +%Y-%m).jsonl"
}

# ── Task específica: roda só ela e sai ───────────────────────────
if [ -n "$SPECIFIC_TASK" ]; then
  if [ -d "$TASKS/pending/$SPECIFIC_TASK" ]; then
    run_task "$SPECIFIC_TASK" "pending" "0"
  elif [ -d "$TASKS/recurring/$SPECIFIC_TASK" ]; then
    run_task "$SPECIFIC_TASK" "recurring" "1"
  else
    echo "[clau] Task '$SPECIFIC_TASK' não encontrada."
    exit 1
  fi
  echo "[clau] Done (task específica)."
  exit 0
fi

# ── Loop: pending primeiro, depois recurring por idade ───────────
task_count=0

# 1) Pending (one-shot) — todas, em ordem alfabética
for task in $(ls -1 "$TASKS/pending/" 2>/dev/null | grep -v '\.gitkeep' | sort); do
  [ -z "$task" ] && continue
  [ "$task_count" -ge "$MAX_TASKS" ] && echo "[clau] Limite de $MAX_TASKS tasks atingido." && break
  run_task "$task" "pending" "0"
  task_count=$((task_count + 1))
done

# 2) Recurring — ordenadas por última execução (mais antiga primeiro)
declare -A recurring_ages
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
  recurring_ages[$name]=$last_epoch
done

# Ordenar por epoch crescente (mais antiga primeiro)
for task in $(for k in "${!recurring_ages[@]}"; do echo "$k ${recurring_ages[$k]}"; done | sort -k2 -n | cut -d' ' -f1); do
  [ "$task_count" -ge "$MAX_TASKS" ] && echo "[clau] Limite de $MAX_TASKS tasks atingido." && break
  run_task "$task" "recurring" "1"
  task_count=$((task_count + 1))
done

if [ "$task_count" -eq 0 ]; then
  echo "[clau] Sem tarefas disponíveis."
else
  echo "[clau] Done — $task_count tasks processadas."
fi
