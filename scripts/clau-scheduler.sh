#!/usr/bin/env bash
# =============================================================================
# clau-scheduler.sh — Unified scheduler for CLAUDINHO workers
# =============================================================================
# Single 10-min timer dispatches all tasks based on budget algorithm.
# Replaces 3 separate timers (every10/every60/every240).
#
# Usage:
#   clau-scheduler.sh              # normal execution
#   clau-scheduler.sh --dry-run    # show what would run without executing
# =============================================================================
set -euo pipefail

PROJECT_DIR="${CLAU_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
VAULT_DIR="${CLAU_VAULT_DIR:-${HOME}/.ovault/Work}"
EPHEMERAL="$PROJECT_DIR/.ephemeral"
SCHEDULER_DIR="$EPHEMERAL/scheduler"
STATE_FILE="$SCHEDULER_DIR/state.json"
COMPLETED_DIR="$SCHEDULER_DIR/completed"
DASHBOARD_FILE="$SCHEDULER_DIR/dashboard.txt"
LOCKFILE="$EPHEMERAL/locks/scheduler.lock"
LOGFILE="$EPHEMERAL/logs/scheduler.log"

TICK_BUDGET="${CLAU_TICK_BUDGET:-540}"  # 9 min default (1 min overhead)
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

TASKS_DIR="$PROJECT_DIR/vault/_agent/tasks"
SCHEDULED_FILE="$VAULT_DIR/scheduled.md"
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

# ── Clock mapping (backward compat) ─────────────────────────────────────────
clock_to_interval() {
  case "$1" in
    every10)  echo 10 ;;
    every60)  echo 60 ;;
    every240) echo 240 ;;
    *)        echo 60 ;;
  esac
}

# ── Parse frontmatter from task CLAUDE.md ────────────────────────────────────
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
  local interval timeout_val clock_val
  interval=$(parse_fm "$task_dir/CLAUDE.md" "interval")
  if [ -n "$interval" ]; then
    echo "$interval"
    return
  fi
  # Fallback: clock → interval mapping
  clock_val=$(parse_fm "$task_dir/CLAUDE.md" "clock")
  clock_to_interval "${clock_val:-every60}"
}

get_timeout() {
  local task_dir="$1"
  local fm
  fm=$(parse_fm "$task_dir/CLAUDE.md" "timeout")
  echo "${fm:-300}"
}

get_model() {
  local task_dir="$1"
  local fm
  fm=$(parse_fm "$task_dir/CLAUDE.md" "model")
  echo "${fm:-haiku}"
}

# ── Discover all recurring tasks ─────────────────────────────────────────────
discover_tasks() {
  local tasks=()
  # From recurring/ directory
  if [ -d "$TASKS_DIR/recurring" ]; then
    for dir in "$TASKS_DIR/recurring"/*/; do
      [ -d "$dir" ] || continue
      [ -f "$dir/CLAUDE.md" ] || continue
      tasks+=("$(basename "$dir")")
    done
  fi
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
    local task_dir="$TASKS_DIR/recurring/$task"
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

# ── Compose dispatch ────────────────────────────────────────────────────────
COMPOSE_BIN="${CLAU_COMPOSE_BIN:-docker-compose}"
COMPOSE_FILES="${CLAU_COMPOSE_FILES:--f $PROJECT_DIR/docker-compose.claude.yml}"

dispatch_tasks() {
  local task_list="$1"
  local clock_label="unified"

  log "Dispatching: $task_list"

  $COMPOSE_BIN $COMPOSE_FILES run --rm -T \
    -e CLAU_WORKER_ID="scheduler-$$" \
    -e CLAU_CLOCK="unified" \
    -e CLAU_TASK_LIST="$task_list" \
    -l clau.scheduler.tick="$(date +%s)" \
    worker /workspace/scripts/clau-runner.sh

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
init_state

# Process any leftover completion markers from previous tick
process_completions

# Check prerequisites
if [ ! -f "$KANBAN_FILE" ] && [ ! -f "$SCHEDULED_FILE" ]; then
  if [ ! -d "$TASKS_DIR/recurring" ] || [ -z "$(ls -A "$TASKS_DIR/recurring" 2>/dev/null)" ]; then
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

  local_model=$(get_model "$TASKS_DIR/recurring/$task")

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
    local_model=$(get_model "$TASKS_DIR/recurring/$task")
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
