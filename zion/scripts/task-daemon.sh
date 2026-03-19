#!/usr/bin/env bash
# task-daemon.sh — Discover due tasks and run them via task-runner.sh
# Usage:
#   task-daemon.sh              # loop (tick every TICK_INTERVAL)
#   PUPPY_SINGLE_TICK=1 task-daemon.sh  # run 1 tick and exit
#   task-daemon.sh --dry-run    # show what would run
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/obsidian/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
STATE_FILE="$WORKSPACE/obsidian/agents/cron/state.json"
LOGFILE="$WORKSPACE/obsidian/agents/cron/daemon.log"
LOCKFILE="$EPHEMERAL/locks/daemon.lock"

TICK_INTERVAL="${PUPPY_TICK_INTERVAL:-600}"
SINGLE_TICK="${PUPPY_SINGLE_TICK:-0}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
RUNNER="$SCRIPT_DIR/task-runner.sh"

mkdir -p "$WORKSPACE/obsidian/agents/cron" "$EPHEMERAL/locks"

log() { echo "[daemon:$(date +%H:%M:%S)] $*"; }

# Rotate log if > 500KB
if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)" -gt 512000 ]; then
  tail -200 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
fi
exec > >(tee -a "$LOGFILE") 2>&1

# Single instance
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  log "Another daemon running — exit."
  exit 0
fi

# ── State helpers ────────────────────────────────────────────────
get_last_run() {
  local task="$1"
  python3 -c "
import json
try:
    s = json.load(open('$STATE_FILE'))
    print(s.get('tasks',{}).get('$task',{}).get('last_run',0))
except: print(0)
" 2>/dev/null || echo 0
}

# ── Frontmatter parser ──────────────────────────────────────────
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
        "${key}:"*) echo "${line#*: }" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; return ;;
      esac
    fi
  done < "$file"
}

task_config() {
  local dir="$1"
  if [ -f "$dir/TASK.md" ]; then echo "$dir/TASK.md"
  elif [ -f "$dir/CLAUDE.md" ]; then echo "$dir/CLAUDE.md"
  else echo ""; fi
}

get_interval() {
  local dir="$1"
  local cfg; cfg=$(task_config "$dir")
  [ -n "$cfg" ] || { echo 60; return; }
  local val; val=$(parse_fm "$cfg" "interval")
  if [ -n "$val" ]; then echo "$val"; return; fi
  # Backward compat: clock -> interval
  local clock; clock=$(parse_fm "$cfg" "clock")
  case "${clock:-every60}" in
    every5m)           echo 5   ;; every10|every10m)  echo 10  ;;
    every15m)          echo 15  ;; every30m)          echo 30  ;;
    every60|every1h)   echo 60  ;; every2h)           echo 120 ;;
    every4h|every240)  echo 240 ;; every6h)           echo 360 ;;
    every12h)          echo 720 ;; every24h|daily*)    echo 1440 ;;
    *)                 echo 60  ;;
  esac
}

# ── Single tick ──────────────────────────────────────────────────
run_tick() {
  [ -f "$STATE_FILE" ] || echo '{"last_tick":"","tasks":{}}' > "$STATE_FILE"

  # Cleanup (optional)
  local cleanup="$SCRIPT_DIR/puppy-cleanup.sh"
  [ -x "$cleanup" ] && "$cleanup" 2>/dev/null || true

  log "=== Tick start ==="
  local now; now=$(date +%s)
  local due=()

  # Scan _scheduled tasks
  for dir in "$TASKS/_scheduled"/*/; do
    [ -d "$dir" ] || continue
    local name; name=$(basename "$dir")
    local cfg; cfg=$(task_config "$dir")
    [ -n "$cfg" ] || continue
    local interval; interval=$(get_interval "$dir")
    local last; last=$(get_last_run "$name")
    local interval_s=$((interval * 60))
    if [ $((now - last)) -ge "$interval_s" ]; then
      due+=("_scheduled:$name")
      log "  due: $name (interval=${interval}m, last=$((now - last))s ago)"
    fi
  done

  # Scan backlog tasks (always due)
  for dir in "$TASKS/backlog"/*/; do
    [ -d "$dir" ] || continue
    local name; name=$(basename "$dir")
    local cfg; cfg=$(task_config "$dir")
    [ -n "$cfg" ] || continue
    due+=("backlog:$name")
    log "  due: $name (backlog)"
  done

  if [ ${#due[@]} -eq 0 ]; then
    log "No tasks due."
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$WORKSPACE/obsidian/agents/cron/heartbeat"
    return 0
  fi

  log "Due: ${#due[@]} tasks"

  if [ "$DRY_RUN" = "1" ]; then
    echo "=== DRY RUN ==="
    for entry in "${due[@]}"; do echo "  would run: $entry"; done
    return 0
  fi

  # Run each task sequentially
  for entry in "${due[@]}"; do
    local source="${entry%%:*}"
    local name="${entry#*:}"
    log "Running: $name ($source)"
    "$RUNNER" "$name" "$source" || log "  $name finished with error"
  done

  log "=== Tick done ==="
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$WORKSPACE/obsidian/agents/cron/heartbeat"
}

# ── Main ─────────────────────────────────────────────────────────
log "Task daemon starting (tick=${TICK_INTERVAL}s, single=$SINGLE_TICK)"

if [ "$SINGLE_TICK" = "1" ] || [ "$DRY_RUN" = "1" ]; then
  run_tick
  exit $?
fi

while true; do
  run_tick || true
  log "Sleeping ${TICK_INTERVAL}s..."
  sleep "$TICK_INTERVAL"
done
