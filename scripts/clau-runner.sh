#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/vault/_agent/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
KANBAN="$WORKSPACE/vault/kanban.md"
CLAU_VERBOSE="${CLAU_VERBOSE:-0}"
SPECIFIC_TASK="${1:-}"
WORKER_ID="${CLAU_WORKER_ID:-worker-1}"
CLAU_TIER="${CLAU_TIER:-heavy}"
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS
export KANBAN_FILE="$KANBAN"
export KANBAN_LOCKFILE="$EPHEMERAL/.kanban.lock"

DEFAULT_TIMEOUT=300
DEFAULT_MODEL="haiku"
DEFAULT_MAX_TURNS=25

mkdir -p "$EPHEMERAL/locks" "$TASKS/running" "$TASKS/done" "$TASKS/failed" \
  "$WORKSPACE/vault/sugestoes" "$WORKSPACE/vault/_agent/reports"

[ -f "$EPHEMERAL/no-mcp.json" ] || echo '{"mcpServers":{}}' > "$EPHEMERAL/no-mcp.json"

source "$WORKSPACE/scripts/kanban-sync.sh"

echo "[clau:$WORKER_ID:$CLAU_TIER] Iniciando (PID $$)"

# ── Per-task lock ────────────────────────────────────────────────
task_lock() {
  local task="$1"
  local lockfile="$EPHEMERAL/locks/${task}.lock"
  exec 201>"$lockfile"
  if ! flock -n 201; then
    echo "[clau:$WORKER_ID] '$task' locked — skip"
    return 1
  fi
}

task_unlock() {
  rm -f "$EPHEMERAL/locks/${1}.lock"
}

# ── Cleanup ──────────────────────────────────────────────────────
cleanup() {
  local sig="${1:-EXIT}"
  for dir in "$TASKS/running"/*/; do
    [ -d "$dir" ] || continue
    local name
    name=$(basename "$dir")
    if [ -f "$dir/.lock" ]; then
      local lock_worker
      lock_worker=$(grep '^worker=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "")
      if [ "$lock_worker" = "$WORKER_ID" ]; then
        local source
        source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
        rm -f "$dir/.lock"
        if [ "$source" = "recurring" ]; then
          mv "$dir" "$TASKS/recurring/$name" 2>/dev/null || rm -rf "$dir"
          kanban_unclaim_recurring "$name" 2>/dev/null || true
        else
          mv "$dir" "$TASKS/pending/$name" 2>/dev/null || rm -rf "$dir"
        fi
        task_unlock "$name"
        echo "[clau:$WORKER_ID] $sig — '$name' devolvida"
      fi
    fi
  done
}
trap 'cleanup SIGINT; exit 1' SIGINT
trap 'cleanup SIGTERM; exit 1' SIGTERM
trap 'cleanup EXIT' EXIT

# ── Frontmatter parser ──────────────────────────────────────────
parse_frontmatter() {
  local file="$1" key="$2"
  [ -f "$file" ] || return
  local in_fm=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      if [ "$in_fm" = "1" ]; then break; fi
      in_fm=1; continue
    fi
    if [ "$in_fm" = "1" ]; then
      case "$line" in
        "${key}:"*) echo "${line#*: }" | tr -d '[:space:]'; return ;;
      esac
    fi
  done < "$file"
}

# ── Task config helpers ──────────────────────────────────────────
get_model() {
  local task_dir="$1"
  [ -n "${CLAU_MODEL:-}" ] && echo "$CLAU_MODEL" && return
  local fm; fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "model")
  echo "${fm:-$DEFAULT_MODEL}"
}

get_timeout() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "timeout")
  echo "${fm:-$DEFAULT_TIMEOUT}"
}

get_tier() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "tier")
  echo "${fm:-heavy}"
}

get_mcp_flags() {
  local task_dir="$1"
  local mcp; mcp=$(parse_frontmatter "$task_dir/CLAUDE.md" "mcp")
  [ "$mcp" = "true" ] && echo "" || echo "--mcp-config $EPHEMERAL/no-mcp.json"
}

get_max_turns() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "max_turns")
  echo "${fm:-$DEFAULT_MAX_TURNS}"
}

# ── Tier filter ──────────────────────────────────────────────────
should_run_tier() {
  local task_dir="$1"
  local task_tier
  task_tier=$(get_tier "$task_dir")
  [ "$CLAU_TIER" = "$task_tier" ]
}

# ── Claim task ───────────────────────────────────────────────────
claim_task() {
  local task="$1" source_dir="$2"
  [ -f "$TASKS/$source_dir/$task/CLAUDE.md" ] || { echo "[clau:$WORKER_ID] '$task' sem CLAUDE.md — skip"; return 1; }
  task_lock "$task" || return 1

  # Tier filter (recurring only — pending always runs on heavy)
  if [ "$source_dir" = "recurring" ] && ! should_run_tier "$TASKS/$source_dir/$task"; then
    echo "[clau:$WORKER_ID] '$task' tier mismatch (task=$(get_tier "$TASKS/$source_dir/$task"), worker=$CLAU_TIER) — skip"
    task_unlock "$task"; return 1
  fi

  # Kanban claim
  if [ "$source_dir" = "recurring" ]; then
    kanban_claim_recurring "$task" "$WORKER_ID" 2>/dev/null || { task_unlock "$task"; return 1; }
  else
    kanban_claim_card "$task" "$WORKER_ID" 2>/dev/null || { task_unlock "$task"; return 1; }
  fi

  # Filesystem
  if [ "$source_dir" = "recurring" ]; then
    cp -r "$TASKS/recurring/$task" "$TASKS/running/$task" 2>/dev/null || {
      kanban_unclaim_recurring "$task" 2>/dev/null || true
      task_unlock "$task"; return 1
    }
  else
    mv "$TASKS/pending/$task" "$TASKS/running/$task" 2>/dev/null || { task_unlock "$task"; return 1; }
  fi

  local task_timeout
  task_timeout=$(get_timeout "$TASKS/running/$task")
  cat > "$TASKS/running/$task/.lock" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$task_timeout
source=$source_dir
worker=$WORKER_ID
pid=$$
EOF
  echo "[clau:$WORKER_ID] Claimed '$task' ($source_dir, ${task_timeout}s)"
}

# ── Build prompt ─────────────────────────────────────────────────
build_task_block() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local context_dir="$EPHEMERAL/notes/$task"
  mkdir -p "$context_dir"

  local instructions context historico recurring_msg
  instructions=$(cat "$TASKS/running/$task/CLAUDE.md")

  context=""
  [ -f "$context_dir/contexto.md" ] && context="
### Contexto anterior
$(cat "$context_dir/contexto.md")"

  historico=""
  [ -f "$context_dir/historico.log" ] && historico="
### Histórico (últimas 20)
$(tail -20 "$context_dir/historico.log")"

  recurring_msg=""
  [ "$is_recurring" = "1" ] && recurring_msg="
### Task recorrente
- Salve estado em: $context_dir/contexto.md
- Priorize, execute o mais importante, salve progresso
- SEMPRE atualize contexto.md no final"

  cat <<BLOCK
## Task: $task
- **Contexto:** $context_dir
- **Tipo:** $([ "$is_recurring" = "1" ] && echo "RECORRENTE" || echo "ONE-SHOT")
- **Worker:** $WORKER_ID

$instructions
$recurring_msg
$context
$historico
BLOCK
}

# ── Run task ─────────────────────────────────────────────────────
run_single_task() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local block logfile
  block=$(build_task_block "$task" "$source_dir" "$is_recurring")

  local memoria=""
  [ -f "$TASKS/running/$task/memoria.md" ] && memoria="
### Memória evolutiva
$(cat "$TASKS/running/$task/memoria.md")"

  logfile="$EPHEMERAL/notes/$task/last-run.log"
  mkdir -p "$EPHEMERAL/notes/$task"

  local task_timeout task_model task_max_turns mcp_flags_str
  task_timeout=$(get_timeout "$TASKS/running/$task")
  task_model=$(get_model "$TASKS/running/$task")
  task_max_turns=$(get_max_turns "$TASKS/running/$task")
  mcp_flags_str=$(get_mcp_flags "$TASKS/running/$task")

  echo "[clau:$WORKER_ID:$task] Claude (model=$task_model, timeout=${task_timeout}s, $(date -u +%H:%M:%S))"

  local mcp_flags=()
  [ -n "$mcp_flags_str" ] && mcp_flags=($mcp_flags_str)

  timeout "$task_timeout" claude --permission-mode bypassPermissions --model "$task_model" \
    --max-turns "$task_max_turns" \
    "${mcp_flags[@]}" \
    -p "Modo autônomo. Task: $task (Worker: $WORKER_ID)
Hora: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Budget: ${task_timeout}s | Model: $task_model

$block
$memoria

## Instruções
1. Siga o protocolo do CLAUDE.md da task
2. Gere o artefato concreto pedido
3. Atualize memoria.md em $TASKS/running/$task/memoria.md
4. Atualize contexto em $EPHEMERAL/notes/$task/contexto.md
5. Se identificar melhorias, salve em $WORKSPACE/vault/sugestoes/\$(date +%Y-%m-%d)-<topico>.md

## IMPORTANTE
- NÃO mova diretórios — o runner cuida do lifecycle
- NÃO edite vault/kanban.md — o runner atualiza
- Registre em $EPHEMERAL/notes/$task/historico.log: TIMESTAMP | ok/fail | duração" 2>&1 | if [ "$CLAU_VERBOSE" = "1" ]; then tee "$logfile"; else cat > "$logfile"; fi
  local exit_code=${PIPESTATUS[0]}

  [ $exit_code -eq 0 ] && echo "[clau:$WORKER_ID:$task] OK" || echo "[clau:$WORKER_ID:$task] FAIL exit=$exit_code"
  tail -3 "$logfile" 2>/dev/null | while IFS= read -r line; do echo "[clau:$WORKER_ID:$task]   $line"; done
  return $exit_code
}

# ── Finish task ──────────────────────────────────────────────────
finish_task() {
  local task="$1" source_dir="$2" exit_code="$3"

  if [ "$source_dir" = "recurring" ]; then
    rm -rf "$TASKS/running/$task"
    kanban_unclaim_recurring "$task" 2>/dev/null || true
    echo "[clau:$WORKER_ID] '$task' cycle done"
  elif [ "$exit_code" -eq 0 ]; then
    mv "$TASKS/running/$task" "$TASKS/done/$task" 2>/dev/null || true
    local report=""
    local report_file
    report_file=$(ls -1t "$WORKSPACE/vault/_agent/reports/"*"$task"* 2>/dev/null | head -1 || true)
    [ -n "$report_file" ] && report="$report_file"
    kanban_complete_card "$task" "$report" 2>/dev/null || true
    echo "[clau:$WORKER_ID] '$task' → done"
  else
    mv "$TASKS/running/$task" "$TASKS/failed/$task" 2>/dev/null || true
    local reason="exit code $exit_code"
    [ "$exit_code" -eq 124 ] && reason="timeout"
    kanban_fail_card "$task" "$reason" 2>/dev/null || true
    echo "[clau:$WORKER_ID] '$task' → failed ($reason)"
  fi
  task_unlock "$task"
}

# ── Specific task mode ───────────────────────────────────────────
if [ -n "$SPECIFIC_TASK" ]; then
  source_dir=""
  is_recurring="0"
  if [ -d "$TASKS/pending/$SPECIFIC_TASK" ]; then
    source_dir="pending"
  elif [ -d "$TASKS/recurring/$SPECIFIC_TASK" ]; then
    source_dir="recurring"; is_recurring="1"
  else
    echo "[clau:$WORKER_ID] Task '$SPECIFIC_TASK' não encontrada."; exit 1
  fi
  claim_task "$SPECIFIC_TASK" "$source_dir" || exit 1
  local_exit=0
  run_single_task "$SPECIFIC_TASK" "$source_dir" "$is_recurring" || local_exit=$?
  finish_task "$SPECIFIC_TASK" "$source_dir" "$local_exit"
  exit 0
fi

# ── Process recurring tasks ──────────────────────────────────────
echo "[clau:$WORKER_ID] === Recorrentes (tier=$CLAU_TIER) ==="
start_time=$SECONDS
ok_count=0; fail_count=0; task_count=0

mapfile -t recurring_names < <(kanban_list_names "Recorrentes" 2>/dev/null)

for task in "${recurring_names[@]}"; do
  [ -z "$task" ] && continue
  claim_task "$task" "recurring" || continue
  task_count=$((task_count + 1))

  local_exit=0
  run_single_task "$task" "recurring" "1" || local_exit=$?
  finish_task "$task" "recurring" "$local_exit"

  [ "$local_exit" -eq 0 ] && ok_count=$((ok_count + 1)) || fail_count=$((fail_count + 1))
done

# ── Process backlog (heavy tier only) ────────────────────────────
if [ "$CLAU_TIER" = "heavy" ]; then
  echo "[clau:$WORKER_ID] === Backlog ==="
  mapfile -t backlog_names < <(kanban_list_names "Backlog" 2>/dev/null)

  for task in "${backlog_names[@]}"; do
    [ -z "$task" ] && continue
    [ -d "$TASKS/pending/$task" ] || continue

    claim_task "$task" "pending" || continue
    task_count=$((task_count + 1))

    local_exit=0
    run_single_task "$task" "pending" "0" || local_exit=$?
    finish_task "$task" "pending" "$local_exit"

    [ "$local_exit" -eq 0 ] && ok_count=$((ok_count + 1)) || fail_count=$((fail_count + 1))
  done
fi

duration=$((SECONDS - start_time))
echo "[clau:$WORKER_ID] Done — $task_count tasks, ${ok_count} ok, ${fail_count} falhas, ${duration}s"
