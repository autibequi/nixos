#!/usr/bin/env bash
# =============================================================================
# puppy-scheduler.sh — Scheduler for Puppy workers (background task runners)
# =============================================================================
# Single 10-min timer dispatches tasks based on budget algorithm.
#
# Usage:
#   puppy-scheduler.sh              # normal execution
#   puppy-scheduler.sh --dry-run    # show what would run without executing
# =============================================================================
set -euo pipefail

PROJECT_DIR="${SCHEDULER_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
VAULT_DIR="${SCHEDULER_VAULT_DIR:-${HOME}/.ovault/Work}"
EPHEMERAL="$PROJECT_DIR/.ephemeral"
SCHEDULER_DIR="$EPHEMERAL/scheduler"
STATE_FILE="$SCHEDULER_DIR/state.json"
COMPLETED_DIR="$SCHEDULER_DIR/completed"
DASHBOARD_FILE="$SCHEDULER_DIR/dashboard.txt"
LOCKFILE="$EPHEMERAL/locks/scheduler.lock"
LOGFILE="$EPHEMERAL/logs/scheduler.log"

TICK_BUDGET="${SCHEDULER_TICK_BUDGET:-540}"  # 9 min default (1 min overhead)
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1
IN_CONTAINER="${SCHEDULER_IN_CONTAINER:-0}"

TASKS_DIR="$VAULT_DIR/tasks"
SCHEDULED_FILE="$VAULT_DIR/agents/task.log.md"
KANBAN_FILE="$VAULT_DIR/kanban.md"

# ── Setup ────────────────────────────────────────────────────────────────────
mkdir -p "$SCHEDULER_DIR" "$COMPLETED_DIR" "$EPHEMERAL/locks" "$EPHEMERAL/logs"

# ── Logging ──────────────────────────────────────────────────────────────────
log() { echo "[scheduler:$(date +%H:%M:%S)] $*"; }

# Rotate log if > 500KB
if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)" -gt 512000 ]; then
  tail -200 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
fi
exec > >(tee -a "$LOGFILE") 2>&1

# ── Flock — single instance ─────────────────────────────────────────────────
if [ "$DRY_RUN" = "0" ]; then
  exec 200>"$LOCKFILE"
  if ! flock -n 200; then
    log "Another scheduler instance running — skip."
    exit 0
  fi
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

# Read a field from state.json for a task: get_state <task> <field>
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

# Update state after task completion
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
# Exponential moving average (alpha=0.3)
old_avg = t.get('avg_duration_s', 0)
t['avg_duration_s'] = round(0.3 * $duration + 0.7 * old_avg) if old_avg > 0 else $duration
t['runs_total'] = t.get('runs_total', 0) + 1
if '$status' != 'ok':
    t['runs_failed'] = t.get('runs_failed', 0) + 1
s['last_tick'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
json.dump(s, open(f, 'w'), indent=2)
" 2>/dev/null
}

# ── Clock mapping (backward compat + new patterns) ──────────────────────────
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

# ── Parse frontmatter from task TASK.md (fallback CLAUDE.md) ─────────────────
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

# Get interval in minutes for a task
get_interval() {
  local task_dir="$1"
  local cfg interval clock_val
  cfg=$(_task_config_file "$task_dir")
  interval=$(parse_fm "$cfg" "interval")
  if [ -n "$interval" ]; then
    echo "$interval"
    return
  fi
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

# ── Discover all recurring tasks ─────────────────────────────────────────────
discover_tasks() {
  local tasks=()
  # From _scheduled/ directory (new) or recurring/ (legacy)
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

# How many seconds overdue (0 if not overdue)
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

# ── Budget estimation ───────────────────────────────────────────────────────
estimate_duration() {
  local task="$1" task_dir="$2"
  local avg timeout_val
  avg=$(get_state "$task" "avg_duration_s")
  timeout_val=$(get_timeout "$task_dir")
  if [ -n "$avg" ] && [ "$avg" -gt 0 ] 2>/dev/null; then
    # avg × 1.5 safety factor, capped at timeout
    local estimate=$(( (avg * 3 + 1) / 2 ))  # integer avg*1.5
    [ "$estimate" -gt "$timeout_val" ] && echo "$timeout_val" || echo "$estimate"
  else
    # No history — use timeout / 2 as initial estimate
    echo $(( timeout_val / 2 ))
  fi
}

# ── Priority sorting ────────────────────────────────────────────────────────
# Output: priority|estimate|interval|task_name
# Priority: 0=every10, 1=every60, 2=every240
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
      10)  priority=0 ;;
      60)  priority=1 ;;
      240) priority=2 ;;
      *)   priority=1 ;;
    esac

    estimate=$(estimate_duration "$task" "$task_dir")
    overdue_s=$(overdue_seconds "$task" "$interval")

    # Force flag: if overdue >= 2x interval, mark as forced
    local forced=0
    local interval_s=$((interval * 60))
    [ "$overdue_s" -ge $((interval_s * 2)) ] && forced=1

    due_tasks+=("${priority}|${estimate}|${interval}|${forced}|${overdue_s}|${task}")
  done < <(discover_tasks)

  # Sort: priority ASC, then within same priority: smaller estimate first (fit more)
  printf '%s\n' "${due_tasks[@]}" | sort -t'|' -k1,1n -k2,2n
}

# ── Compose dispatch (host) / in-process dispatch (container) ─────────────────
COMPOSE_BIN="${SCHEDULER_COMPOSE_BIN:-docker-compose}"
COMPOSE_FILES="${SCHEDULER_COMPOSE_FILES:--f $PROJECT_DIR/zion/cli/docker-compose.puppy.yml}"

dispatch_tasks() {
  local task_list="$1"
  log "Dispatching: $task_list"

  if [ "$IN_CONTAINER" = "1" ]; then
    export SCHEDULER_WORKER_ID="scheduler-$$"
    export SCHEDULER_CLOCK="unified"
    export SCHEDULER_TASK_LIST="$task_list"
    "${PROJECT_DIR}/scripts/puppy-runner.sh"
    return $?
  fi

  # Garantir mount do vault: OBSIDIAN_PATH na hora do parse do YAML (compose usa para volumes)
  export OBSIDIAN_PATH="${OBSIDIAN_PATH:-$VAULT_DIR}"
  OBSIDIAN_PATH="$OBSIDIAN_PATH" $COMPOSE_BIN $COMPOSE_FILES run --rm -T \
    -e OBSIDIAN_PATH="$OBSIDIAN_PATH" \
    -e SCHEDULER_WORKER_ID="scheduler-$$" \
    -e SCHEDULER_CLOCK="unified" \
    -e SCHEDULER_TASK_LIST="$task_list" \
    -l clau.scheduler.tick="$(date +%s)" \
    worker /workspace/nixos/scripts/puppy-runner.sh

  return $?
}

# ── Process completed markers ───────────────────────────────────────────────
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

# ── Main ─────────────────────────────────────────────────────────────────────
# When running inside scheduler container, run cleanup at start of tick
if [ "$IN_CONTAINER" = "1" ]; then
  SCHEDULER_VAULT_DIR="$VAULT_DIR" SCHEDULER_PROJECT_DIR="$PROJECT_DIR" \
    "${PROJECT_DIR}/scripts/puppy-cleanup.sh" 2>/dev/null || true
fi

init_state

# Process any leftover completion markers from previous tick
process_completions

# Check prerequisites — _scheduled/ is authoritative; kanban only needed for one-shot tasks
_has_recurring=0
[ -d "$TASKS_DIR/_scheduled" ] && [ -n "$(ls -A "$TASKS_DIR/_scheduled" 2>/dev/null)" ] && _has_recurring=1
[ "$_has_recurring" -eq 0 ] && [ -d "$TASKS_DIR/recurring" ] && [ -n "$(ls -A "$TASKS_DIR/recurring" 2>/dev/null)" ] && _has_recurring=1

if [ "$_has_recurring" -eq 0 ]; then
  if [ ! -f "$KANBAN_FILE" ] && [ ! -f "$SCHEDULED_FILE" ]; then
    log "No kanban/scheduled/recurring tasks found."
    exit 0
  fi
fi

log "=== Tick start (budget=${TICK_BUDGET}s) ==="

# Build priority queue
mapfile -t queue < <(build_task_queue)

if [ ${#queue[@]} -eq 0 ]; then
  log "No tasks due."
  exit 0
fi

# Budget allocation
budget_remaining=$TICK_BUDGET
selected_tasks=()
skipped_tasks=()

for entry in "${queue[@]}"; do
  [ -z "$entry" ] && continue
  IFS='|' read -r priority estimate interval forced overdue_s task <<< "$entry"

  if [ -d "$TASKS_DIR/_scheduled/$task" ]; then _tdir="$TASKS_DIR/_scheduled/$task"
  else _tdir="$TASKS_DIR/recurring/$task"; fi
  local_model=$(get_model "$_tdir")

  if [ "$estimate" -le "$budget_remaining" ]; then
    # Fits in budget
    budget_remaining=$((budget_remaining - estimate))
    selected_tasks+=("$task")
    log "  [P${priority}] $task (est=${estimate}s, model=$local_model) → SELECTED (budget left: ${budget_remaining}s)"
  elif [ "$priority" -eq 0 ]; then
    # P0 always runs
    budget_remaining=$((budget_remaining - estimate))
    selected_tasks+=("$task")
    log "  [P0] $task (est=${estimate}s) → FORCED (P0 always runs, budget: ${budget_remaining}s)"
  elif [ "$forced" -eq 1 ]; then
    # Overdue >= 2x interval — force it
    budget_remaining=$((budget_remaining - estimate))
    selected_tasks+=("$task")
    log "  [P${priority}] $task (est=${estimate}s, overdue=${overdue_s}s) → FORCED (overdue, budget: ${budget_remaining}s)"
  else
    skipped_tasks+=("$task")
    log "  [P${priority}] $task (est=${estimate}s) → SKIPPED (budget insufficient)"
  fi
done

if [ ${#selected_tasks[@]} -eq 0 ]; then
  log "No tasks selected after budget allocation."
  exit 0
fi

task_csv=$(IFS=,; echo "${selected_tasks[*]}")
budget_used=$((TICK_BUDGET - budget_remaining))

log "Selected ${#selected_tasks[@]} tasks: $task_csv"
log "Budget: ${budget_used}/${TICK_BUDGET}s allocated"
[ ${#skipped_tasks[@]} -gt 0 ] && log "Skipped: ${skipped_tasks[*]}"

# ── Dry run ──────────────────────────────────────────────────────────────────
if [ "$DRY_RUN" = "1" ]; then
  echo ""
  echo "=== DRY RUN ==="
  echo "Would dispatch: $task_csv"
  echo "Budget: ${budget_used}/${TICK_BUDGET}s"
  echo ""
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
  exit 0
fi

# ── Dispatch ─────────────────────────────────────────────────────────────────
dispatch_tasks "$task_csv"
dispatch_exit=$?

# Process completion markers written by runner
process_completions

log "=== Tick done (exit=$dispatch_exit) ==="
