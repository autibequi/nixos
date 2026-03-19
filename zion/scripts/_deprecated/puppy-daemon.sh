#!/usr/bin/env bash
# =============================================================================
# puppy-daemon.sh — Internal scheduler for persistent Puppy container
# =============================================================================
# Runs inside the persistent puppy container. Discovers due tasks and runs
# them sequentially via puppy-runner.sh.
#
# Usage:
#   puppy-daemon.sh              # normal loop (tick every PUPPY_TICK_INTERVAL)
#   PUPPY_SINGLE_TICK=1 puppy-daemon.sh  # run 1 tick and exit
#   puppy-daemon.sh --dry-run    # show what would run without executing
# =============================================================================
set -euo pipefail

WORKSPACE="/workspace"
VAULT_DIR="$WORKSPACE/obsidian"
EPHEMERAL="$WORKSPACE/.ephemeral"
# Persistent state/logs → Obsidian (survive container restarts)
# Fallback to .ephemeral if Obsidian is not mounted
if [ -d "$VAULT_DIR" ]; then
  CRON_DIR="$VAULT_DIR/agents/cron"
else
  CRON_DIR="$EPHEMERAL/cron"
fi
STATE_FILE="$CRON_DIR/state.json"
LOGFILE="$CRON_DIR/daemon.log"
# Ephemeral state → .ephemeral (locks/completions are intentionally reset on restart)
SCHEDULER_DIR="$EPHEMERAL/scheduler"
COMPLETED_DIR="$SCHEDULER_DIR/completed"
LOCKFILE="$EPHEMERAL/locks/daemon.lock"

TICK_INTERVAL="${PUPPY_TICK_INTERVAL:-600}"  # 10 min default
TICK_BUDGET="${PUPPY_TICK_BUDGET:-540}"      # 9 min default
SINGLE_TICK="${PUPPY_SINGLE_TICK:-0}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

TASKS_DIR="$VAULT_DIR/tasks"
TASK_LOG="$VAULT_DIR/agents/task.log.md"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
RUNNER="$SCRIPT_DIR/puppy-runner.sh"

# ── Setup ────────────────────────────────────────────────────────────────────
mkdir -p "$CRON_DIR" "$CRON_DIR/runs" "$SCHEDULER_DIR" "$COMPLETED_DIR" "$EPHEMERAL/locks"

# ── Logging ──────────────────────────────────────────────────────────────────
log() { echo "[daemon:$(date +%H:%M:%S)] $*"; }

# Rotate log if > 500KB
if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)" -gt 512000 ]; then
  tail -200 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
fi
exec > >(tee -a "$LOGFILE") 2>&1

# ── Flock — single instance ─────────────────────────────────────────────────
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  log "Another daemon instance running — exit."
  exit 0
fi

# ── State management ────────────────────────────────────────────────────────
init_state() {
  [ -f "$STATE_FILE" ] && return
  cat > "$STATE_FILE" <<'EOF'
{
  "last_tick": "",
  "tasks": {}
}
EOF
}

get_state() {
  local task="$1" field="$2"
  python3 -c "
import json, sys
try:
    s = json.load(open('$STATE_FILE'))
    v = s.get('tasks', {}).get('$task', {}).get('$field', '')
    print(v if v != '' else '')
except: pass
" 2>/dev/null
}

update_state() {
  local task="$1" duration="$2" status="$3"
  python3 -c "
import json, time
f = '$STATE_FILE'
s = json.load(open(f))
t = s.setdefault('tasks', {}).setdefault('$task', {
    'last_run': 0, 'last_status': '', 'last_duration_s': 0,
    'avg_duration_s': 0, 'runs_total': 0, 'runs_failed': 0
})
t['last_run'] = int(time.time())
t['last_status'] = '$status'
t['last_duration_s'] = $duration
old_avg = t.get('avg_duration_s', 0)
t['avg_duration_s'] = round(0.3 * $duration + 0.7 * old_avg) if old_avg > 0 else $duration
t['runs_total'] = t.get('runs_total', 0) + 1
if '$status' != 'ok':
    t['runs_failed'] = t.get('runs_failed', 0) + 1
s['last_tick'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
json.dump(s, open(f, 'w'), indent=2)
" 2>/dev/null
}

# ── Clock mapping ────────────────────────────────────────────────────────────
clock_to_interval() {
  case "$1" in
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

# ── Parse frontmatter ────────────────────────────────────────────────────────
_task_config_file() {
  local task_dir="$1"
  if [ -f "$task_dir/TASK.md" ]; then echo "$task_dir/TASK.md"
  else echo "$task_dir/CLAUDE.md"
  fi
}

parse_fm() {
  local file="$1" key="$2"
  [ -f "$file" ] || return
  local in_fm=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      [ "$in_fm" = "1" ] && break
      in_fm=1; continue
    fi
    if [ "$in_fm" = "1" ]; then
      case "$line" in
        "${key}:"*) echo "${line#*: }" | tr -d '[:space:]'; return ;;
      esac
    fi
  done < "$file"
}

get_interval() {
  local task_dir="$1"
  local cfg interval clock_val
  cfg=$(_task_config_file "$task_dir")
  interval=$(parse_fm "$cfg" "interval")
  if [ -n "$interval" ]; then echo "$interval"; return; fi
  clock_val=$(parse_fm "$cfg" "clock")
  clock_to_interval "${clock_val:-every60}"
}

get_timeout() {
  local task_dir="$1"
  local fm
  fm=$(parse_fm "$(_task_config_file "$task_dir")" "timeout")
  echo "${fm:-300}"
}

get_model() {
  local task_dir="$1"
  local fm
  fm=$(parse_fm "$(_task_config_file "$task_dir")" "model")
  echo "${fm:-haiku}"
}

# ── Discover recurring tasks ─────────────────────────────────────────────────
discover_tasks() {
  local tasks=()
  for sched_dir in "$TASKS_DIR/_scheduled" "$TASKS_DIR/recurring"; do
    [ -d "$sched_dir" ] || continue
    for dir in "$sched_dir"/*/; do
      [ -d "$dir" ] || continue
      [ -f "$dir/TASK.md" ] || [ -f "$dir/CLAUDE.md" ] || continue
      tasks+=("$(basename "$dir")")
    done
  done
  printf '%s\n' "${tasks[@]}"
}

# ── Check if task is due ────────────────────────────────────────────────────
is_due() {
  local task="$1" interval_min="$2"
  local last_run now interval_s
  last_run=$(get_state "$task" "last_run")
  last_run="${last_run:-0}"
  now=$(date +%s)
  interval_s=$((interval_min * 60))
  [ $((now - last_run)) -ge "$interval_s" ]
}

overdue_seconds() {
  local task="$1" interval_min="$2"
  local last_run now interval_s
  last_run=$(get_state "$task" "last_run")
  last_run="${last_run:-0}"
  now=$(date +%s)
  interval_s=$((interval_min * 60))
  local diff=$((now - last_run - interval_s))
  [ "$diff" -gt 0 ] && echo "$diff" || echo "0"
}

# ── Budget estimation ────────────────────────────────────────────────────────
estimate_duration() {
  local task="$1" task_dir="$2"
  local avg timeout_val
  avg=$(get_state "$task" "avg_duration_s")
  timeout_val=$(get_timeout "$task_dir")
  if [ -n "$avg" ] && [ "$avg" -gt 0 ] 2>/dev/null; then
    local estimate=$(( (avg * 3 + 1) / 2 ))
    [ "$estimate" -gt "$timeout_val" ] && echo "$timeout_val" || echo "$estimate"
  else
    echo $(( timeout_val / 2 ))
  fi
}

# ── Build priority queue ────────────────────────────────────────────────────
build_task_queue() {
  local -a due_tasks=()

  while IFS= read -r task; do
    [ -z "$task" ] && continue
    local task_dir
    if [ -d "$TASKS_DIR/_scheduled/$task" ]; then
      task_dir="$TASKS_DIR/_scheduled/$task"
    else
      task_dir="$TASKS_DIR/recurring/$task"
    fi
    local interval
    interval=$(get_interval "$task_dir")

    is_due "$task" "$interval" || continue

    local priority estimate overdue_s
    case "$interval" in
      5|10)  priority=0 ;;
      60)    priority=1 ;;
      *)     priority=2 ;;
    esac

    estimate=$(estimate_duration "$task" "$task_dir")
    overdue_s=$(overdue_seconds "$task" "$interval")

    local forced=0
    local interval_s=$((interval * 60))
    local last_run_val
    last_run_val=$(get_state "$task" "last_run")
    # Only force if task has run before (last_run > 0) and is very overdue
    if [ -n "$last_run_val" ] && [ "$last_run_val" != "0" ] && [ "$overdue_s" -ge $((interval_s * 2)) ]; then
      forced=1
    fi

    due_tasks+=("${priority}|${estimate}|${interval}|${forced}|${overdue_s}|${task}")
  done < <(discover_tasks)

  printf '%s\n' "${due_tasks[@]}" | sort -t'|' -k1,1n -k2,2n
}

# ── Process completion markers ───────────────────────────────────────────────
process_completions() {
  for marker in "$COMPLETED_DIR"/*.done; do
    [ -f "$marker" ] || continue
    local task duration status
    task=$(basename "$marker" .done)
    duration=$(grep '^duration=' "$marker" 2>/dev/null | cut -d= -f2 || echo "0")
    status=$(grep '^status=' "$marker" 2>/dev/null | cut -d= -f2 || echo "unknown")
    update_state "$task" "$duration" "$status"
    rm -f "$marker"
    log "Recorded: $task (${duration}s, $status)"
  done
}

# ── Run cleanup ──────────────────────────────────────────────────────────────
run_cleanup() {
  local cleanup="$SCRIPT_DIR/puppy-cleanup.sh"
  [ -x "$cleanup" ] && "$cleanup" 2>/dev/null || true
}

# ── Single tick ──────────────────────────────────────────────────────────────
run_tick() {
  init_state
  run_cleanup
  process_completions

  log "=== Tick start (budget=${TICK_BUDGET}s) ==="

  mapfile -t queue < <(build_task_queue)

  if [ ${#queue[@]} -eq 0 ]; then
    log "No tasks due."
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CRON_DIR/heartbeat"
    return 0
  fi

  # Budget allocation
  local budget_remaining=$TICK_BUDGET
  local selected_tasks=()
  local skipped_tasks=()

  for entry in "${queue[@]}"; do
    [ -z "$entry" ] && continue
    IFS='|' read -r priority estimate interval forced overdue_s task <<< "$entry"

    local _tdir
    if [ -d "$TASKS_DIR/_scheduled/$task" ]; then _tdir="$TASKS_DIR/_scheduled/$task"
    else _tdir="$TASKS_DIR/recurring/$task"; fi
    local local_model
    local_model=$(get_model "$_tdir")

    if [ "$estimate" -le "$budget_remaining" ]; then
      budget_remaining=$((budget_remaining - estimate))
      selected_tasks+=("$task")
      log "  [P${priority}] $task (est=${estimate}s, model=$local_model) -> SELECTED (budget left: ${budget_remaining}s)"
    elif [ "$priority" -eq 0 ]; then
      budget_remaining=$((budget_remaining - estimate))
      selected_tasks+=("$task")
      log "  [P0] $task (est=${estimate}s) -> FORCED (P0 always runs, budget: ${budget_remaining}s)"
    elif [ "$forced" -eq 1 ]; then
      budget_remaining=$((budget_remaining - estimate))
      selected_tasks+=("$task")
      log "  [P${priority}] $task (est=${estimate}s, overdue=${overdue_s}s) -> FORCED (overdue, budget: ${budget_remaining}s)"
    else
      skipped_tasks+=("$task")
      log "  [P${priority}] $task (est=${estimate}s) -> SKIPPED (budget insufficient)"
    fi
  done

  if [ ${#selected_tasks[@]} -eq 0 ]; then
    log "No tasks selected after budget allocation."
    return 0
  fi

  local task_csv
  task_csv=$(IFS=,; echo "${selected_tasks[*]}")
  local budget_used=$((TICK_BUDGET - budget_remaining))

  log "Selected ${#selected_tasks[@]} tasks: $task_csv"
  log "Budget: ${budget_used}/${TICK_BUDGET}s allocated"
  [ ${#skipped_tasks[@]} -gt 0 ] && log "Skipped: ${skipped_tasks[*]}"

  # Dry run
  if [ "$DRY_RUN" = "1" ]; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would dispatch: $task_csv"
    echo "Budget: ${budget_used}/${TICK_BUDGET}s"
    for entry in "${queue[@]}"; do
      [ -z "$entry" ] && continue
      IFS='|' read -r priority estimate interval forced overdue_s task <<< "$entry"
      if [ -d "$TASKS_DIR/_scheduled/$task" ]; then _tdir="$TASKS_DIR/_scheduled/$task"
      else _tdir="$TASKS_DIR/recurring/$task"; fi
      local_model=$(get_model "$_tdir")
      local_avg=$(get_state "$task" "avg_duration_s")
      printf "  %-20s P%d  int=%3dm  est=%4ds  avg=%4ss  model=%-6s\n" \
        "$task" "$priority" "$interval" "$estimate" "${local_avg:-?}" "$local_model"
    done
    return 0
  fi

  # Dispatch: run tasks sequentially via puppy-runner.sh
  log "Dispatching: $task_csv"
  export SCHEDULER_WORKER_ID="daemon-$$"
  export SCHEDULER_CLOCK="unified"
  export SCHEDULER_TASK_LIST="$task_csv"
  "$RUNNER"
  local dispatch_exit=$?

  process_completions
  log "=== Tick done (exit=$dispatch_exit) ==="

  # Heartbeat — proof that daemon ran (visible in Obsidian)
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CRON_DIR/heartbeat"
}

# ── Main loop ────────────────────────────────────────────────────────────────
log "Puppy daemon starting (tick=${TICK_INTERVAL}s, budget=${TICK_BUDGET}s, single=${SINGLE_TICK})"

if [ "$SINGLE_TICK" = "1" ] || [ "$DRY_RUN" = "1" ]; then
  run_tick
  exit $?
fi

while true; do
  run_tick || true
  log "Sleeping ${TICK_INTERVAL}s..."
  sleep "$TICK_INTERVAL"
done
