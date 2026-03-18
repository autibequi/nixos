#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/obsidian/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
KANBAN="$WORKSPACE/obsidian/kanban.md"
SCHEDULER_VERBOSE="${SCHEDULER_VERBOSE:-0}"
SPECIFIC_TASK="${1:-}"
WORKER_ID="${SCHEDULER_WORKER_ID:-worker-1}"
SCHEDULER_CLOCK="${SCHEDULER_CLOCK:-unified}"
SCHEDULER_TASK_LIST="${SCHEDULER_TASK_LIST:-}"  # comma-separated list from scheduler
# Completion markers — always in workspace ephemeral (daemon reads them in-process)
SCHEDULER_COMPLETED_DIR="$EPHEMERAL/scheduler/completed"
# Identidade desta execução — permite detectar órfãos mesmo quando runner é PID 1 (container)
RUN_ID="$$-$(date +%s)-${RANDOM:-0}"
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS
SCHEDULED="$WORKSPACE/obsidian/agents/task.log.md"
TASK_LOG="$WORKSPACE/obsidian/agents/task.log.md"
MURAL="$WORKSPACE/obsidian/MURAL.md"
export KANBAN_FILE="$KANBAN"
export SCHEDULED_FILE="$SCHEDULED"
export KANBAN_LOCKFILE="$EPHEMERAL/.kanban.lock"

DEFAULT_TIMEOUT=300
DEFAULT_MODEL="haiku"
DEFAULT_MAX_TURNS=12


mkdir -p "$EPHEMERAL/locks" "$TASKS/doing" "$TASKS/done" "$TASKS/cancelled" \
  "$WORKSPACE/obsidian/agents/reports" "$WORKSPACE/obsidian/agents/diarios"

# Presença em .ephemeral/agents/ — puppies = workers em background (Zion = sessões interativas)
AGENTS_ROOT="$WORKSPACE/.ephemeral/agents"
AGENT_MY_DIR="$AGENTS_ROOT/puppy_${HOSTNAME:-unknown}_$$"
mkdir -p "$AGENTS_ROOT"
# Limpa pastas órfãs (container morreu com SIGKILL/crash — trap não rodou)
now_agent=$(date +%s)
for stale in "$AGENTS_ROOT"/puppy_*/; do
  [ -d "$stale" ] || continue
  [ -f "$stale/.live" ] || continue
  mod=$(stat -c %Y "$stale/.live" 2>/dev/null || echo 0)
  [ $(( now_agent - mod )) -gt 900 ] && rm -rf "$stale"
done
mkdir -p "$AGENT_MY_DIR"
echo "started=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$AGENT_MY_DIR/.live"
echo "worker=$WORKER_ID" >> "$AGENT_MY_DIR/.live"
echo "clock=$SCHEDULER_CLOCK" >> "$AGENT_MY_DIR/.live"
trap 'rm -rf "$AGENT_MY_DIR"' EXIT

[ -f "$EPHEMERAL/no-mcp.json" ] || echo '{"mcpServers":{}}' > "$EPHEMERAL/no-mcp.json"

source "$(dirname "$(readlink -f "$0")")/kanban-sync.sh"

echo "[puppy:$WORKER_ID:$SCHEDULER_CLOCK] Iniciando (PID $$)"

# ── Per-task lock ────────────────────────────────────────────────
task_lock() {
  local task="$1"
  local lockfile="$EPHEMERAL/locks/${task}.lock"
  exec 201>"$lockfile"
  if ! flock -n 201; then
    echo "[puppy:$WORKER_ID] '$task' locked — skip"
    return 1
  fi
}

task_unlock() {
  rm -f "$EPHEMERAL/locks/${1}.lock"
}

# ── Orphan recovery ──────────────────────────────────────────────
# Tasks presas em running/ com PID morto ou expiradas por tempo
recover_orphans() {
  local now
  now=$(date +%s)
  local grace=60  # segundos extras após timeout antes de declarar orphan

  for dir in "$TASKS/doing"/*/; do
    [ -d "$dir" ] || continue
    local name
    name=$(basename "$dir")
    [ -f "$dir/.lock" ] || continue

    local lock_pid lock_started lock_timeout lock_source lock_worker lock_run_id
    lock_pid=$(grep '^pid=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "")
    lock_started=$(grep '^started=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "")
    lock_timeout=$(grep '^timeout=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "300")
    lock_source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "backlog")
    lock_worker=$(grep '^worker=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "")
    lock_run_id=$(grep '^run_id=' "$dir/.lock" 2>/dev/null | cut -d= -f2- || echo "")

    local is_orphan=0

    # Mesmo worker: lock de outra execução (outro container/processo) → órfão (resolve pid=1)
    if [ "$lock_worker" = "$WORKER_ID" ] && [ -n "$lock_run_id" ] && [ "$lock_run_id" != "$RUN_ID" ]; then
      is_orphan=1
    # Outro worker: NUNCA usar run_id (cada runner tem RUN_ID diferente); só processo morto ou timeout
    # pid=1 de outro worker: não dá pra kill -0 1 (pode ser nós), deixar só timeout tratar
    elif [ "$lock_worker" != "$WORKER_ID" ]; then
      if [ -n "$lock_pid" ] && [ "$lock_pid" != "1" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
        is_orphan=1
      fi
    # Mesmo worker, lock antigo sem run_id: pid=1 não rastreável
    elif [ "$lock_pid" = "1" ] && [ -z "$lock_run_id" ]; then
      is_orphan=1
    # Processo morto (nosso worker, pid != 1)
    elif [ -n "$lock_pid" ] && [ "$lock_pid" != "1" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      is_orphan=1
    fi

    # Timeout expirado — ground truth independente do PID
    if [ -n "$lock_started" ]; then
      local started_ts
      started_ts=$(date -d "$lock_started" +%s 2>/dev/null || echo "0")
      local deadline=$(( started_ts + lock_timeout + grace ))
      if [ "$now" -gt "$deadline" ]; then
        is_orphan=1
      fi
    fi

    [ "$is_orphan" = "0" ] && continue

    echo "[puppy:$WORKER_ID] Orphan: '$name' (pid=${lock_pid}, worker=${lock_worker}, run_id=${lock_run_id:-<none>}, started=${lock_started}) — recuperando"

    rm -f "$dir/.lock"
    task_unlock "$name" 2>/dev/null || true

    if [ "$lock_source" = "_scheduled" ] || [ "$lock_source" = "recurring" ]; then
      rm -rf "$dir"
      kanban_unclaim_recurring "$name" 2>/dev/null || true
      echo "[puppy:$WORKER_ID] '$name' orphan → _scheduled"
    else
      mv "$dir" "$TASKS/backlog/$name" 2>/dev/null || true
      kanban_unclaim_card "$name" 2>/dev/null || true
      echo "[puppy:$WORKER_ID] '$name' orphan → backlog"
    fi
  done
}

# ── Cleanup ──────────────────────────────────────────────────────
cleanup() {
  local sig="${1:-EXIT}"
  for dir in "$TASKS/doing"/*/; do
    [ -d "$dir" ] || continue
    local name
    name=$(basename "$dir")
    if [ -f "$dir/.lock" ]; then
      local lock_worker
      lock_worker=$(grep '^worker=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "")
      if [ "$lock_worker" = "$WORKER_ID" ]; then
        local source
        source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "backlog")
        rm -f "$dir/.lock"
        if [ "$source" = "_scheduled" ] || [ "$source" = "recurring" ]; then
          mv "$dir" "$TASKS/_scheduled/$name" 2>/dev/null || rm -rf "$dir"
          kanban_unclaim_recurring "$name" 2>/dev/null || true
        else
          mv "$dir" "$TASKS/backlog/$name" 2>/dev/null || rm -rf "$dir"
        fi
        task_unlock "$name"
        echo "[puppy:$WORKER_ID] $sig — '$name' devolvida"
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

# ── Task config file (TASK.md with CLAUDE.md fallback) ───────────
task_config_file() {
  local task_dir="$1"
  if [ -f "$task_dir/TASK.md" ]; then echo "$task_dir/TASK.md"
  else echo "$task_dir/CLAUDE.md"
  fi
}

# ── Task config helpers ──────────────────────────────────────────
get_model() {
  local task_dir="$1"
  [ -n "${SCHEDULER_MODEL:-}" ] && echo "$SCHEDULER_MODEL" && return
  local fm; fm=$(parse_frontmatter "$(task_config_file "$task_dir")" "model")
  echo "${fm:-$DEFAULT_MODEL}"
}

get_timeout() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$(task_config_file "$task_dir")" "timeout")
  echo "${fm:-$DEFAULT_TIMEOUT}"
}

get_clock() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$(task_config_file "$task_dir")" "clock")
  echo "${fm:-every60}"
}

get_mcp_flags() {
  local task_dir="$1"
  local mcp; mcp=$(parse_frontmatter "$(task_config_file "$task_dir")" "mcp")
  [ "$mcp" = "true" ] && echo "" || echo "--mcp-config $EPHEMERAL/no-mcp.json"
}

get_max_turns() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$(task_config_file "$task_dir")" "max_turns")
  echo "${fm:-$DEFAULT_MAX_TURNS}"
}

get_wave() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$(task_config_file "$task_dir")" "wave")
  echo "${fm:-1}"
}

get_depends_on() {
  local task_dir="$1"
  local fm; fm=$(parse_frontmatter "$(task_config_file "$task_dir")" "depends_on")
  echo "${fm:-}"
}

# ── Wave execution ───────────────────────────────────────────────
group_by_wave() {
  local tasks=("$@")
  declare -A wave_tasks

  for task in "${tasks[@]}"; do
    local w
    w=$(get_wave "$TASKS/backlog/$task")
    wave_tasks[$w]="${wave_tasks[$w]:-} $task"
  done
  
  for w in $(echo "${!wave_tasks[@]}" | tr ' ' '\n' | sort -n); do
    echo "$w:${wave_tasks[$w]}"
  done
}

run_wave_parallel() {
  local wave_num="$1"
  shift
  local tasks=("$@")
  
  echo "[puppy:$WORKER_ID] Wave $wave_num: ${tasks[*]} (parallel)"
  
  local pids=()
  for task in "${tasks[@]}"; do
    (
      claim_task "$task" "backlog" || exit 1
      run_single_task "$task" "backlog" "0"
      local exit_code=$?
      finish_task "$task" "backlog" "$exit_code"
      exit $exit_code
    ) &
    pids+=($!)
  done
  
  local wave_ok=0 wave_fail=0
  for pid in "${pids[@]}"; do
    wait $pid || {
      [ $? -ne 0 ] && wave_fail=$((wave_fail + 1)) || wave_ok=$((wave_ok + 1))
    }
  done
  
  echo "[puppy:$WORKER_ID] Wave $wave_num done: ${wave_ok} ok, ${wave_fail} failed"
}

# ── Interval helper (backward compat: clock → interval) ─────────
get_interval() {
  local task_dir="$1"
  local interval
  interval=$(parse_frontmatter "$(task_config_file "$task_dir")" "interval")
  if [ -n "$interval" ]; then echo "$interval"; return; fi
  local clock_val
  clock_val=$(get_clock "$task_dir")
  case "$clock_val" in
    every5m)             echo 5   ;;
    every10|every10m)    echo 10  ;;
    every15m)            echo 15  ;;
    every30m)            echo 30  ;;
    every60|every60m|every1h) echo 60 ;;
    every2h)             echo 120 ;;
    every4h|every240)    echo 240 ;;
    every6h)             echo 360 ;;
    every12h)            echo 720 ;;
    every24h|daily)      echo 1440 ;;
    daily@*)             echo 1440 ;;
    *)                   echo 60  ;;
  esac
}

# ── Clock filter ─────────────────────────────────────────────────
should_run_clock() {
  local task_dir="$1"
  # Unified scheduler: task list is pre-filtered, always run
  [ "$SCHEDULER_CLOCK" = "unified" ] && return 0
  local task_clock
  task_clock=$(get_clock "$task_dir")
  [ "$SCHEDULER_CLOCK" = "$task_clock" ]
}

# ── Claim task ───────────────────────────────────────────────────
claim_task() {
  local task="$1" source_dir="$2"
  local task_dir="$TASKS/$source_dir/$task"
  local config_file
  config_file=$(task_config_file "$task_dir")
  [ -f "$config_file" ] || { echo "[puppy:$WORKER_ID] '$task' sem TASK.md/CLAUDE.md — skip"; return 1; }
  task_lock "$task" || return 1

  # Clock filter
  if ! should_run_clock "$task_dir"; then
    echo "[puppy:$WORKER_ID] '$task' clock mismatch (task=$(get_clock "$task_dir"), worker=$SCHEDULER_CLOCK) — skip"
    task_unlock "$task"; return 1
  fi

  # Kanban claim (best-effort, kanban.md may be retired)
  if [ "$source_dir" = "_scheduled" ] || [ "$source_dir" = "recurring" ]; then
    kanban_claim_recurring "$task" "$WORKER_ID" 2>/dev/null || true
  else
    kanban_claim_card "$task" "$WORKER_ID" 2>/dev/null || true
  fi

  # Filesystem
  if [ "$source_dir" = "_scheduled" ] || [ "$source_dir" = "recurring" ]; then
    cp -r "$TASKS/$source_dir/$task" "$TASKS/doing/$task" 2>/dev/null || {
      task_unlock "$task"; return 1
    }
  else
    mv "$TASKS/$source_dir/$task" "$TASKS/doing/$task" 2>/dev/null || { task_unlock "$task"; return 1; }
  fi

  local task_timeout
  task_timeout=$(get_timeout "$TASKS/doing/$task")
  cat > "$TASKS/doing/$task/.lock" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$task_timeout
source=$source_dir
worker=$WORKER_ID
pid=$$
run_id=$RUN_ID
EOF
  echo "[puppy:$WORKER_ID] Claimed '$task' ($source_dir, ${task_timeout}s)"

  # Log task start
  echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $task | ▶ start | $(get_model "$TASKS/doing/$task") | — |" >> "$TASK_LOG" 2>/dev/null || true
}

# ── Run task ─────────────────────────────────────────────────────
run_single_task() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local logfile
  logfile="$EPHEMERAL/notes/$task/last-run.log"
  mkdir -p "$EPHEMERAL/notes/$task"

  local task_timeout task_model task_max_turns mcp_flags_str
  task_timeout=$(get_timeout "$TASKS/doing/$task")
  task_model=$(get_model "$TASKS/doing/$task")
  task_max_turns=$(get_max_turns "$TASKS/doing/$task")
  mcp_flags_str=$(get_mcp_flags "$TASKS/doing/$task")

  echo "[puppy:$WORKER_ID:$task] Claude (model=$task_model, timeout=${task_timeout}s, $(date -u +%H:%M:%S))"

  local mcp_flags=()
  [ -n "$mcp_flags_str" ] && mcp_flags=($mcp_flags_str)

  local task_type="ONE-SHOT"
  [ "$is_recurring" = "1" ] && task_type="RECORRENTE"

  timeout "$task_timeout" claude \
    --agent-file /home/claude/.claude/agents/puppy-runner/agent.md \
    --permission-mode bypassPermissions \
    --model "$task_model" \
    --max-turns "$task_max_turns" \
    "${mcp_flags[@]}" \
    -p "Processe a task: $task (Worker: $WORKER_ID)
Task dir: $TASKS/doing/$task
Context dir: $EPHEMERAL/notes/$task
MURAL: $MURAL
Tipo: $task_type
Hora: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Budget: ${task_timeout}s" 2>&1 | if [ "$SCHEDULER_VERBOSE" = "1" ]; then tee "$logfile"; else cat > "$logfile"; fi
  local exit_code=${PIPESTATUS[0]}

  [ $exit_code -eq 0 ] && echo "[puppy:$WORKER_ID:$task] OK" || echo "[puppy:$WORKER_ID:$task] FAIL exit=$exit_code"
  tail -3 "$logfile" 2>/dev/null | while IFS= read -r line; do echo "[puppy:$WORKER_ID:$task]   $line"; done
  return $exit_code
}

# ── Finish task ──────────────────────────────────────────────────
update_mural_kanban() {
  local mural="$MURAL"
  [ -f "$mural" ] || return 0
  local tasks_dir="$TASKS"
  local row=""
  for col in inbox backlog doing done _waiting blocked cancelled; do
    local items
    items=$(ls "$tasks_dir/$col/"*.md 2>/dev/null | xargs -I{} basename {} .md 2>/dev/null | \
      head -5 | tr '\n' ', ' | sed 's/,$//' || echo "")
    # Also count folders (task dirs)
    local folder_items
    folder_items=$(ls -d "$tasks_dir/$col"/*/ 2>/dev/null | xargs -I{} basename {} 2>/dev/null | \
      head -5 | tr '\n' ', ' | sed 's/,$//' || echo "")
    [ -z "$items" ] && items="$folder_items"
    [ -z "$items" ] && items="—"
    row="$row| $items "
  done
  row="$row|"
  local new_kanban="## Kanban\n\n| inbox | backlog | doing | done | _waiting | blocked | cancelled |\n|-------|---------|-------|------|----------|---------|-----------|\n$row"
  # Replace between markers using python3 for reliability
  python3 -c "
import re, sys
content = open('$mural').read()
new_section = '''$new_kanban'''
pattern = r'<!-- KANBAN:START[^>]*-->.*?<!-- KANBAN:END -->'
replacement = '<!-- KANBAN:START — auto-gerado pelo runner, não editar manualmente -->\n' + new_section + '\n<!-- KANBAN:END -->'
new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
open('$mural', 'w').write(new_content)
" 2>/dev/null || true
}

finish_task() {
  local task="$1" source_dir="$2" exit_code="$3"
  local task_elapsed_fmt
  task_elapsed_fmt="$((${TASK_ELAPSED:-0}/60))m$((${TASK_ELAPSED:-0}%60))s"
  local task_model_log
  task_model_log=$(get_model "$TASKS/doing/$task" 2>/dev/null || echo "haiku")

  # Auto-tracking: fechar worktree virtual
  "$(dirname "$(readlink -f "$0")")/worktree-manager.sh" exit 2>/dev/null || true

  if [ "$source_dir" = "_scheduled" ] || [ "$source_dir" = "recurring" ]; then
    # Sync back evolved files to _scheduled/ before cleanup
    for sync_file in memoria.md TASK.md CLAUDE.md; do
      if [ -f "$TASKS/doing/$task/$sync_file" ]; then
        cp "$TASKS/doing/$task/$sync_file" "$TASKS/_scheduled/$task/$sync_file" 2>/dev/null || true
      fi
    done
    rm -rf "$TASKS/doing/$task"
    kanban_unclaim_recurring "$task" 2>/dev/null || true
    local log_icon="✅"; [ "$exit_code" -ne 0 ] && log_icon="❌"
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $task | $log_icon done | $task_model_log | $task_elapsed_fmt |" >> "$TASK_LOG" 2>/dev/null || true
    echo "[puppy:$WORKER_ID] '$task' cycle done"
  elif [ "$exit_code" -eq 0 ]; then
    mv "$TASKS/doing/$task" "$TASKS/done/$task" 2>/dev/null || true
    local report_file
    report_file=$(ls -1t "$WORKSPACE/obsidian/agents/reports/"*"$task"* 2>/dev/null | head -1 || true)
    kanban_complete_card "$task" "${report_file:-}" 2>/dev/null || true
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $task | ✅ done | $task_model_log | $task_elapsed_fmt |" >> "$TASK_LOG" 2>/dev/null || true
    echo "[puppy:$WORKER_ID] '$task' → done"
  else
    mv "$TASKS/doing/$task" "$TASKS/cancelled/$task" 2>/dev/null || true
    local reason="exit code $exit_code"
    [ "$exit_code" -eq 124 ] && reason="timeout"
    kanban_fail_card "$task" "$reason" 2>/dev/null || true
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $task | ❌ cancelled | $task_model_log | $task_elapsed_fmt |" >> "$TASK_LOG" 2>/dev/null || true
    echo "[puppy:$WORKER_ID] '$task' → cancelled ($reason)"
  fi
  task_unlock "$task"

  # Update MURAL kanban view
  update_mural_kanban 2>/dev/null || true

  # Fresh context: limpar tool-results cache para esta task
  cleanup_task_cache "$task"

  # Write completion marker for unified scheduler
  local task_duration="${TASK_ELAPSED:-${SECONDS:-0}}"
  write_completion_marker "$task" "$task_duration" "$exit_code"
}

cleanup_task_cache() {
  local task="$1"
  local claude_home="${HOME}/.claude"
  [ -d "$claude_home/projects" ] || return
  for proj in "$claude_home/projects"/*/; do
    [ -d "$proj/tool-results" ] || continue
    find "$proj/tool-results" -type d -name "*${task}*" -exec rm -rf {} + 2>/dev/null || true
  done
}

# ── Completion marker (for unified scheduler) ────────────────────────────────
write_completion_marker() {
  local task="$1" duration="$2" exit_code="$3"
  mkdir -p "$SCHEDULER_COMPLETED_DIR"
  local status="ok"
  [ "$exit_code" -ne 0 ] && status="fail"
  [ "$exit_code" -eq 124 ] && status="timeout"
  cat > "$SCHEDULER_COMPLETED_DIR/${task}.done" <<EOF
task=$task
duration=$duration
status=$status
exit_code=$exit_code
completed=$(date -u +%Y-%m-%dT%H:%M:%SZ)
worker=$WORKER_ID
EOF
}

# ── Task list mode (unified scheduler) ───────────────────────────
if [ -n "$SCHEDULER_TASK_LIST" ]; then
  recover_orphans
  IFS=',' read -ra TASK_NAMES <<< "$SCHEDULER_TASK_LIST"
  echo "[puppy:$WORKER_ID] Task list mode: ${TASK_NAMES[*]}"
  # Debug: onde o worker está procurando as tasks (ajuda quando 0 tasks = mount errado)
  [ "$SCHEDULER_VERBOSE" = "1" ] && echo "[puppy:$WORKER_ID] TASKS base: $TASKS (_scheduled: $TASKS/_scheduled, backlog: $TASKS/backlog)"
  if [ ! -d "$TASKS/_scheduled" ] && [ ! -d "$TASKS/backlog" ]; then
    echo "[puppy:$WORKER_ID] AVISO: nem _scheduled/ nem backlog/ existem em $TASKS — confira mount de /workspace/obsidian (OBSIDIAN_PATH no host)" >&2
  fi

  ok_count=0; fail_count=0; task_count=0
  for task in "${TASK_NAMES[@]}"; do
    [ -z "$task" ] && continue
    task=$(echo "$task" | tr -d '[:space:]')
    touch "$AGENT_MY_DIR/.live" 2>/dev/null || true

    source_dir=""
    is_recurring="0"
    if [ -d "$TASKS/_scheduled/$task" ]; then
      source_dir="_scheduled"; is_recurring="1"
    elif [ -d "$TASKS/backlog/$task" ]; then
      source_dir="backlog"
    else
      echo "[puppy:$WORKER_ID] '$task' not found in _scheduled/ or backlog/ — skip (checado: $TASKS/_scheduled/$task e $TASKS/backlog/$task)"
      continue
    fi

    claim_task "$task" "$source_dir" || continue
    task_count=$((task_count + 1))

    task_start_s=$SECONDS
    local_exit=0
    run_single_task "$task" "$source_dir" "$is_recurring" || local_exit=$?
    TASK_ELAPSED=$((SECONDS - task_start_s)) finish_task "$task" "$source_dir" "$local_exit"

    [ "$local_exit" -eq 0 ] && ok_count=$((ok_count + 1)) || fail_count=$((fail_count + 1))
  done

  echo "[puppy:$WORKER_ID] Task list done — $task_count tasks, ${ok_count} ok, ${fail_count} fail"
  exit 0
fi

# ── Specific task mode ───────────────────────────────────────────
if [ -n "$SPECIFIC_TASK" ]; then
  source_dir=""
  is_recurring="0"
  if [ -d "$TASKS/doing/$SPECIFIC_TASK" ]; then
    # Already in doing/ (e.g. claimed by daemon) — run in-place without re-claiming
    echo "[puppy:$WORKER_ID] '$SPECIFIC_TASK' already in doing/ — running in-place"
    is_recurring="1"  # treat as recurring (don't move to done)
    local_exit=0
    run_single_task "$SPECIFIC_TASK" "doing" "$is_recurring" || local_exit=$?
    echo "[puppy:$WORKER_ID] '$SPECIFIC_TASK' in-place run done (exit=$local_exit)"
    exit $local_exit
  elif [ -d "$TASKS/backlog/$SPECIFIC_TASK" ]; then
    source_dir="backlog"
  elif [ -d "$TASKS/_scheduled/$SPECIFIC_TASK" ]; then
    source_dir="_scheduled"; is_recurring="1"
  else
    echo "[puppy:$WORKER_ID] Task '$SPECIFIC_TASK' não encontrada."; exit 1
  fi
  claim_task "$SPECIFIC_TASK" "$source_dir" || exit 1
  local_exit=0
  run_single_task "$SPECIFIC_TASK" "$source_dir" "$is_recurring" || local_exit=$?
  finish_task "$SPECIFIC_TASK" "$source_dir" "$local_exit"
  exit 0
fi

recover_orphans

# ── Process recurring tasks ──────────────────────────────────────
touch "$AGENT_MY_DIR/.live" 2>/dev/null || true
echo "[puppy:$WORKER_ID] === Recorrentes (_scheduled, clock=$SCHEDULER_CLOCK) ==="
start_time=$SECONDS
ok_count=0; fail_count=0; task_count=0

# Discover _scheduled tasks from filesystem (kanban.md retired)
mapfile -t recurring_names < <(
  for d in "$TASKS/_scheduled"/*/; do
    [ -d "$d" ] || continue
    basename "$d"
  done
)

for task in "${recurring_names[@]}"; do
  [ -z "$task" ] && continue
  claim_task "$task" "_scheduled" || continue
  task_count=$((task_count + 1))

  local_exit=0
  run_single_task "$task" "_scheduled" "1" || local_exit=$?
  TASK_ELAPSED=$((SECONDS - start_time)) finish_task "$task" "_scheduled" "$local_exit"

  [ "$local_exit" -eq 0 ] && ok_count=$((ok_count + 1)) || fail_count=$((fail_count + 1))
done

# ── Process backlog ───────────────────────────────────────────────
touch "$AGENT_MY_DIR/.live" 2>/dev/null || true
echo "[puppy:$WORKER_ID] === Backlog ==="

# Discover backlog tasks from filesystem (ignore _waiting/)
mapfile -t backlog_names < <(
  for f in "$TASKS/backlog"/*.md "$TASKS/backlog"/*/; do
    [ -e "$f" ] || continue
    basename "$f" .md
  done | sort -u
)

filter_by_clock() {
  local filtered=()
  for task in "${backlog_names[@]}"; do
    [ -z "$task" ] && continue
    [ -d "$TASKS/backlog/$task" ] || continue
    task_clock=$(get_clock "$TASKS/backlog/$task")
    [ "$task_clock" = "$SCHEDULER_CLOCK" ] && filtered+=("$task")
  done
  printf '%s\n' "${filtered[@]}"
}

clock_filtered=()
while IFS= read -r t; do clock_filtered+=("$t"); done < <(filter_by_clock)

has_wave_support() {
  for task in "${clock_filtered[@]}"; do
    local cfg; cfg=$(task_config_file "$TASKS/backlog/$task")
    [ -f "$cfg" ] || continue
    local wave
    wave=$(get_wave "$TASKS/backlog/$task")
    [ "$wave" != "1" ] && return 0
  done
  return 1
}

if [ ${#clock_filtered[@]} -gt 0 ] && has_wave_support; then
  echo "[puppy:$WORKER_ID] Executando em modo WAVE"

  while IFS=':' read -r wave_num wave_tasks; do
    [ -z "$wave_num" ] && continue
    read -ra task_array <<< "$wave_tasks"
    [ ${#task_array[@]} -eq 0 ] && continue

    run_wave_parallel "$wave_num" "${task_array[@]}"
    task_count=$((task_count + ${#task_array[@]}))
  done < <(group_by_wave "${clock_filtered[@]}")
else
  for task in "${clock_filtered[@]}"; do
    [ -z "$task" ] && continue
    [ -d "$TASKS/backlog/$task" ] || continue

    claim_task "$task" "backlog" || continue
    task_count=$((task_count + 1))

    local_exit=0
    run_single_task "$task" "backlog" "0" || local_exit=$?
    TASK_ELAPSED=$((SECONDS - start_time)) finish_task "$task" "backlog" "$local_exit"

    [ "$local_exit" -eq 0 ] && ok_count=$((ok_count + 1)) || fail_count=$((fail_count + 1))
  done
fi

duration=$((SECONDS - start_time))
echo "[puppy:$WORKER_ID] Done — $task_count tasks, ${ok_count} ok, ${fail_count} falhas, ${duration}s"
