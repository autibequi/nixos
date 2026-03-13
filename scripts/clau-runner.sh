#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/vault/_agent/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
KANBAN="$WORKSPACE/vault/kanban.md"
CLAU_VERBOSE="${CLAU_VERBOSE:-0}"
SPECIFIC_TASK="${1:-}"
WORKER_ID="${CLAU_WORKER_ID:-worker-1}"
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS
export KANBAN_FILE="$KANBAN"
export KANBAN_LOCKFILE="$EPHEMERAL/.kanban.lock"

# Defaults (overridden by frontmatter)
DEFAULT_TIMEOUT_RECURRING=300
DEFAULT_TIMEOUT_PENDING=900
DEFAULT_MODEL_RECURRING="haiku"
DEFAULT_MODEL_PENDING="sonnet"
DEFAULT_SCHEDULE="night"
DEFAULT_MAX_TURNS=25

mkdir -p "$EPHEMERAL/locks" "$TASKS/running" "$TASKS/done" "$TASKS/failed" \
  "$WORKSPACE/vault/sugestoes" "$WORKSPACE/vault/_agent/reports"

# Ensure no-mcp config exists
[ -f "$EPHEMERAL/no-mcp.json" ] || echo '{"mcpServers":{}}' > "$EPHEMERAL/no-mcp.json"

# Source kanban-sync library
source "$WORKSPACE/scripts/kanban-sync.sh"

echo "[clau:$WORKER_ID] Iniciando (PID $$)"

# ── Per-task lock (prevents two workers picking same task) ────────
task_lock() {
  local task="$1"
  local lockfile="$EPHEMERAL/locks/${task}.lock"
  exec 201>"$lockfile"
  if ! flock -n 201; then
    echo "[clau:$WORKER_ID] '$task' locked por outro worker — skip"
    return 1
  fi
  return 0
}

task_unlock() {
  local task="$1"
  rm -f "$EPHEMERAL/locks/${task}.lock"
}

# ── Cleanup ao sair ──────────────────────────────────────────────
cleanup() {
  local sig="${1:-EXIT}"
  # Unclaim any tasks this worker has in Em Andamento
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
          echo "[clau:$WORKER_ID] $sig — '$name' devolvida pra recurring/"
        else
          mv "$dir" "$TASKS/pending/$name" 2>/dev/null || rm -rf "$dir"
          # Move back from Em Andamento to Backlog (best-effort)
          echo "[clau:$WORKER_ID] $sig — '$name' devolvida pra pending/"
        fi
        task_unlock "$name"
      fi
    fi
  done
}
trap 'cleanup SIGINT; exit 1' SIGINT
trap 'cleanup SIGTERM; exit 1' SIGTERM
trap 'cleanup EXIT' EXIT

# ── Frontmatter parser ───────────────────────────────────────────
parse_frontmatter() {
  local file="$1" key="$2"
  [ -f "$file" ] || return
  local in_fm=0 line
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      if [ "$in_fm" = "1" ]; then break; fi
      in_fm=1
      continue
    fi
    if [ "$in_fm" = "1" ]; then
      case "$line" in
        "${key}:"*)
          echo "${line#*: }" | tr -d '[:space:]'
          return
          ;;
      esac
    fi
  done < "$file"
}

# ── Scheduling: day/night ────────────────────────────────────────
is_daytime() {
  local hour
  hour=$(date +%H)
  [ "$hour" -ge 7 ] && [ "$hour" -le 23 ]
}

should_run_task() {
  local task_dir="$1" source="$2"
  [ "$source" = "pending" ] && return 0
  local schedule
  schedule=$(parse_frontmatter "$task_dir/CLAUDE.md" "schedule")
  schedule=${schedule:-$DEFAULT_SCHEDULE}
  [ "$schedule" = "always" ] && return 0
  ! is_daytime && return 0
  return 1
}

# ── Model / Timeout / MCP / Max turns ────────────────────────────
get_model() {
  local task_dir="$1" source="$2"
  [ -n "${CLAU_MODEL:-}" ] && echo "$CLAU_MODEL" && return
  local fm
  fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "model")
  [ -n "$fm" ] && echo "$fm" && return
  [ "$source" = "recurring" ] && echo "$DEFAULT_MODEL_RECURRING" || echo "$DEFAULT_MODEL_PENDING"
}

get_timeout() {
  local task_dir="$1" source="$2"
  local fm
  fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "timeout")
  [ -n "$fm" ] && echo "$fm" && return
  [ "$source" = "recurring" ] && echo "$DEFAULT_TIMEOUT_RECURRING" || echo "$DEFAULT_TIMEOUT_PENDING"
}

get_mcp_flags() {
  local task_dir="$1"
  local mcp
  mcp=$(parse_frontmatter "$task_dir/CLAUDE.md" "mcp")
  if [ "$mcp" = "true" ]; then
    echo ""
  else
    echo "--mcp-config $EPHEMERAL/no-mcp.json"
  fi
}

get_max_turns() {
  local task_dir="$1"
  local fm
  fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "max_turns")
  [ -n "$fm" ] && echo "$fm" && return
  echo "$DEFAULT_MAX_TURNS"
}

# ── Claim task (kanban + filesystem) ─────────────────────────────
claim_task() {
  local task="$1" source_dir="$2"
  if [ ! -f "$TASKS/$source_dir/$task/CLAUDE.md" ]; then
    echo "[clau:$WORKER_ID] '$task' sem CLAUDE.md — skip"
    return 1
  fi
  # Per-task lock
  if ! task_lock "$task"; then
    return 1
  fi
  # Check schedule
  if ! should_run_task "$TASKS/$source_dir/$task" "$source_dir"; then
    echo "[clau:$WORKER_ID] '$task' schedule=night, agora é dia — skip"
    task_unlock "$task"
    return 1
  fi
  # Kanban claim
  if [ "$source_dir" = "recurring" ]; then
    kanban_claim_recurring "$task" "$WORKER_ID" 2>/dev/null || {
      echo "[clau:$WORKER_ID] '$task' já claimed no kanban — skip"
      task_unlock "$task"
      return 1
    }
  else
    kanban_claim_card "$task" "$WORKER_ID" 2>/dev/null || {
      echo "[clau:$WORKER_ID] '$task' não encontrado no Backlog — skip"
      task_unlock "$task"
      return 1
    }
  fi
  # Filesystem: copy recurring or move pending to running
  if [ "$source_dir" = "recurring" ]; then
    cp -r "$TASKS/recurring/$task" "$TASKS/running/$task" 2>/dev/null || {
      echo "[clau:$WORKER_ID] '$task' copy failed — skip"
      kanban_unclaim_recurring "$task" 2>/dev/null || true
      task_unlock "$task"
      return 1
    }
  else
    if ! mv "$TASKS/pending/$task" "$TASKS/running/$task" 2>/dev/null; then
      echo "[clau:$WORKER_ID] '$task' sumiu (race condition?) — skip"
      task_unlock "$task"
      return 1
    fi
  fi
  local task_timeout
  task_timeout=$(get_timeout "$TASKS/running/$task" "$source_dir")
  cat > "$TASKS/running/$task/.lock" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$task_timeout
source=$source_dir
worker=$WORKER_ID
pid=$$
EOF
  echo "[clau:$WORKER_ID] Claimed '$task' ($source_dir, timeout=${task_timeout}s)"
  return 0
}

# ── Build prompt block ───────────────────────────────────────────
build_task_block() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local context_dir="$EPHEMERAL/notes/$task"
  mkdir -p "$context_dir"

  local instructions context historico recurring_msg
  instructions=$(cat "$TASKS/running/$task/CLAUDE.md")

  context=""
  [ -f "$context_dir/contexto.md" ] && context="
### Contexto da execução anterior
$(cat "$context_dir/contexto.md")"

  historico=""
  [ -f "$context_dir/historico.log" ] && historico="
### Histórico de execuções (últimas 20)
$(tail -20 "$context_dir/historico.log")"

  recurring_msg=""
  if [ "$is_recurring" = "1" ]; then
    recurring_msg="
### Task recorrente (imortal)
- Salve seu estado em: $context_dir/contexto.md
- Use $context_dir/ para arquivos auxiliares
- Não tente fazer tudo de uma vez — priorize, execute o mais importante, salve progresso
- SEMPRE atualize contexto.md no final"
  fi

  cat <<BLOCK
---
## Task: $task
- **Diretório da tarefa:** $TASKS/running/$task
- **Diretório de contexto:** $context_dir
- **Tipo:** $([ "$is_recurring" = "1" ] && echo "RECORRENTE (imortal)" || echo "ONE-SHOT")
- **Source:** $source_dir
- **Worker:** $WORKER_ID

$instructions
$recurring_msg
$context
$historico

BLOCK
}

# ── Executar UMA task ────────────────────────────────────────────
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
  task_timeout=$(get_timeout "$TASKS/running/$task" "$source_dir")
  task_model=$(get_model "$TASKS/running/$task" "$source_dir")
  task_max_turns=$(get_max_turns "$TASKS/running/$task")
  mcp_flags_str=$(get_mcp_flags "$TASKS/running/$task")

  echo "[clau:$WORKER_ID:$task] Iniciando Claude (model=$task_model, timeout=${task_timeout}s, turns=$task_max_turns, $(date -u +%H:%M:%S))..."

  local mcp_flags=()
  if [ -n "$mcp_flags_str" ]; then
    # shellcheck disable=SC2086
    mcp_flags=($mcp_flags_str)
  fi

  timeout "$task_timeout" claude --permission-mode bypassPermissions --model "$task_model" \
    --max-turns "$task_max_turns" \
    "${mcp_flags[@]}" \
    -p "Modo autônomo. Tarefa: $task (Worker: $WORKER_ID)
Hora atual: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Budget: ${task_timeout}s (~$(( task_timeout / 60 ))min)
Model: $task_model

$block
$memoria

## Instruções de execução
1. Siga o protocolo descrito no CLAUDE.md da task
2. Gere o artefato concreto que a task pede
3. Atualize memoria.md em $TASKS/running/$task/memoria.md com timestamp, o que fez, o que aprendeu, próximos passos
4. Atualize contexto efêmero em $EPHEMERAL/notes/$task/contexto.md
5. Se a task permite auto-evolução, reflita e edite o CLAUDE.md se necessário
6. Se identificar melhorias/ideias/problemas, salve sugestão em $WORKSPACE/vault/sugestoes/\$(date +%Y-%m-%d)-<topico>.md

## IMPORTANTE
- NÃO mova diretórios entre pending/running/done/failed — o runner cuida disso
- NÃO edite vault/kanban.md — o runner atualiza automaticamente
- Foque em executar a task e gerar artefatos
- Registre resultado em $EPHEMERAL/notes/$task/historico.log (formato: TIMESTAMP | ok ou fail | duração)
- Registre uso em $EPHEMERAL/usage/$(date +%Y-%m).jsonl: {\"date\":\"TIMESTAMP\",\"task\":\"$task\",\"duration\":N,\"status\":\"STATUS\",\"type\":\"$([ "$is_recurring" = "1" ] && echo recurring || echo oneshot)\",\"model\":\"$task_model\"}
- Resuma em uma linha." 2>&1 | if [ "$CLAU_VERBOSE" = "1" ]; then tee "$logfile"; else cat > "$logfile"; fi
  local exit_code=${PIPESTATUS[0]}

  if [ $exit_code -eq 0 ]; then
    echo "[clau:$WORKER_ID:$task] OK ($(date -u +%H:%M:%S))"
  else
    echo "[clau:$WORKER_ID:$task] FAIL exit=$exit_code ($(date -u +%H:%M:%S))"
  fi
  echo "[clau:$WORKER_ID:$task] --- últimas linhas ---"
  tail -5 "$logfile" 2>/dev/null | while IFS= read -r line; do echo "[clau:$WORKER_ID:$task]   $line"; done
  echo "[clau:$WORKER_ID:$task] --- log: $logfile ---"
  return $exit_code
}

# ── Finish task (kanban + filesystem) ────────────────────────────
finish_task() {
  local task="$1" source_dir="$2" exit_code="$3"
  local is_recurring=0
  [ "$source_dir" = "recurring" ] && is_recurring=1

  if [ "$is_recurring" = "1" ]; then
    # Recurring: remove copy from running, unclaim from kanban
    rm -rf "$TASKS/running/$task"
    kanban_unclaim_recurring "$task" 2>/dev/null || true
    echo "[clau:$WORKER_ID] '$task' (recurring) cycle done"
  elif [ "$exit_code" -eq 0 ]; then
    # One-shot success: move to done, complete in kanban
    mv "$TASKS/running/$task" "$TASKS/done/$task" 2>/dev/null || true
    # Check for report
    local report=""
    local report_file
    report_file=$(ls -1t "$WORKSPACE/vault/_agent/reports/"*"$task"* 2>/dev/null | head -1 || true)
    [ -n "$report_file" ] && report="$report_file"
    kanban_complete_card "$task" "$report" 2>/dev/null || true
    echo "[clau:$WORKER_ID] '$task' → done"
  else
    # One-shot failure: move to failed, fail in kanban
    mv "$TASKS/running/$task" "$TASKS/failed/$task" 2>/dev/null || true
    local reason="exit code $exit_code"
    [ "$exit_code" -eq 124 ] && reason="timeout"
    kanban_fail_card "$task" "$reason" 2>/dev/null || true
    echo "[clau:$WORKER_ID] '$task' → failed ($reason)"
  fi
  task_unlock "$task"
}

# ── Task específica: roda só ela e sai ───────────────────────────
if [ -n "$SPECIFIC_TASK" ]; then
  source_dir=""
  is_recurring="0"
  if [ -d "$TASKS/pending/$SPECIFIC_TASK" ]; then
    source_dir="pending"
  elif [ -d "$TASKS/recurring/$SPECIFIC_TASK" ]; then
    source_dir="recurring"
    is_recurring="1"
  else
    echo "[clau:$WORKER_ID] Task '$SPECIFIC_TASK' não encontrada."
    exit 1
  fi

  claim_task "$SPECIFIC_TASK" "$source_dir" || exit 1
  local_exit=0
  run_single_task "$SPECIFIC_TASK" "$source_dir" "$is_recurring" || local_exit=$?
  finish_task "$SPECIFIC_TASK" "$source_dir" "$local_exit"

  echo "[clau:$WORKER_ID] Done (task específica)."
  exit 0
fi

# ── Processar Recorrentes (do kanban) ────────────────────────────
echo "[clau:$WORKER_ID] === Processando Recorrentes ==="
start_time=$SECONDS
ok_count=0
fail_count=0
task_count=0

# Ler nomes das tasks recorrentes do kanban
mapfile -t recurring_names < <(kanban_list_names "Recorrentes" 2>/dev/null)

# Ordenar por última execução (oldest first)
declare -A recurring_ages
for name in "${recurring_names[@]}"; do
  [ -z "$name" ] && continue
  ctx="$EPHEMERAL/notes/$name/historico.log"
  if [ -f "$ctx" ]; then
    last_ts=$(tail -1 "$ctx" | cut -d'|' -f1 | xargs)
    last_epoch=$(date -d "$last_ts" +%s 2>/dev/null || echo "0")
  else
    last_epoch=0
  fi
  recurring_ages[$name]=$last_epoch
done

for task in $(for k in "${!recurring_ages[@]}"; do echo "$k ${recurring_ages[$k]}"; done | sort -k2 -n | cut -d' ' -f1); do
  claim_task "$task" "recurring" || continue
  task_count=$((task_count + 1))

  local_exit=0
  run_single_task "$task" "recurring" "1" || local_exit=$?
  finish_task "$task" "recurring" "$local_exit"

  if [ "$local_exit" -eq 0 ]; then
    ok_count=$((ok_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

# ── Processar Backlog (one-shots do kanban) ──────────────────────
echo "[clau:$WORKER_ID] === Processando Backlog ==="

mapfile -t backlog_names < <(kanban_list_names "Backlog" 2>/dev/null)

for task in "${backlog_names[@]}"; do
  [ -z "$task" ] && continue
  # Check if task dir exists in pending
  [ -d "$TASKS/pending/$task" ] || continue
  # Check if #dead
  local card_line
  card_line=$(kanban_read_column "Falhou" 2>/dev/null | grep "**${task}**" | head -1 || true)
  [[ "$card_line" == *"#dead"* ]] && continue

  claim_task "$task" "pending" || continue
  task_count=$((task_count + 1))

  local_exit=0
  run_single_task "$task" "pending" "0" || local_exit=$?
  finish_task "$task" "pending" "$local_exit"

  if [ "$local_exit" -eq 0 ]; then
    ok_count=$((ok_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

duration=$((SECONDS - start_time))
echo "[clau:$WORKER_ID] Done — $task_count tasks, ${ok_count} ok, ${fail_count} falhas, ${duration}s total"

# ── Dashboard generation ─────────────────────────────────────────
generate_dashboard() {
  local vault_dir="$WORKSPACE/vault"
  local dashboard="$vault_dir/dashboard.md"
  mkdir -p "$vault_dir"

  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local recurring_count backlog_count andamento_count
  recurring_count=$(kanban_count "Recorrentes" 2>/dev/null || echo "0")
  backlog_count=$(kanban_count "Backlog" 2>/dev/null || echo "0")
  andamento_count=$(kanban_count "Em Andamento" 2>/dev/null || echo "0")

  cat > "$dashboard" <<DASH
# Claudinho Dashboard
Atualizado: $now | Worker: $WORKER_ID

## Saúde do Sistema
- Última execução: $now (${duration}s, $ok_count ok / $fail_count falhas)
- Kanban: $recurring_count recorrentes, $backlog_count backlog, $andamento_count em andamento

## Últimas Execuções
| Task | Status | Model | Quando |
|------|--------|-------|--------|
DASH

  local usage_file="$EPHEMERAL/usage/$(date +%Y-%m).jsonl"
  if [ -f "$usage_file" ]; then
    tail -15 "$usage_file" | while IFS= read -r line; do
      local t_name t_status t_date t_model
      t_name=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task','?'))" 2>/dev/null || echo "?")
      t_status=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "?")
      t_date=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('date','?'))" 2>/dev/null || echo "?")
      t_model=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('model','?'))" 2>/dev/null || echo "?")
      echo "| $t_name | $t_status | $t_model | $t_date |" >> "$dashboard"
    done
  fi

  cat >> "$dashboard" <<DASH

## Tasks Recorrentes
| Task | Schedule | Model |
|------|----------|-------|
DASH

  for dir in "$TASKS/recurring"/*/; do
    [ -d "$dir" ] || continue
    local tname tschedule tmodel
    tname=$(basename "$dir")
    tschedule=$(parse_frontmatter "$dir/CLAUDE.md" "schedule")
    tschedule=${tschedule:-night}
    tmodel=$(parse_frontmatter "$dir/CLAUDE.md" "model")
    tmodel=${tmodel:-$DEFAULT_MODEL_RECURRING}
    echo "| $tname | $tschedule | $tmodel |" >> "$dashboard"
  done

  cat >> "$dashboard" <<DASH

## Backlog (Kanban)
DASH

  kanban_read_column "Backlog" 2>/dev/null >> "$dashboard" || true

  if [ "$fail_count" -gt 0 ]; then
    cat >> "$dashboard" <<DASH

## Alertas
- $fail_count tasks falharam nesta execução ($WORKER_ID)
DASH
  fi

  echo "[clau:$WORKER_ID] Dashboard gerado: $dashboard"
}

generate_dashboard 2>/dev/null || echo "[clau:$WORKER_ID] Dashboard generation failed (non-critical)"

# ── Health endpoint (JSON for Waybar) ────────────────────────────
generate_health() {
  local health_file="$EPHEMERAL/health.json"
  local status_text="ok"
  local status_class="ok"
  [ "$fail_count" -gt 0 ] && status_text="${ok_count}ok/${fail_count}fail" && status_class="warning"
  [ "$ok_count" -eq 0 ] && [ "$fail_count" -gt 0 ] && status_class="critical"

  cat > "$health_file" <<JSON
{"text":"${ok_count}/${task_count}","tooltip":"Claudinho ($WORKER_ID): ${ok_count} ok, ${fail_count} fail, ${duration}s","class":"$status_class","alt":"$status_text"}
JSON
  echo "[clau:$WORKER_ID] Health endpoint: $health_file"
}

generate_health 2>/dev/null || true

# ── Desktop notification ─────────────────────────────────────────
if command -v notify-send &>/dev/null; then
  _icon="dialog-information"
  [ "$fail_count" -gt 0 ] && _icon="dialog-warning"
  notify-send -i "$_icon" "Claudinho ($WORKER_ID)" "$ok_count ok, $fail_count falhas em ${duration}s" 2>/dev/null || true
fi
