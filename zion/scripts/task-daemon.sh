#!/usr/bin/env bash
# task-daemon.sh — Scan TODO/ for due cards and run them
# Cards are due if their date prefix (YYYYMMDD_HH_MM) is <= now + 10min
# Usage:
#   task-daemon.sh              # loop
#   TASK_SINGLE_TICK=1 task-daemon.sh  # 1 tick
#   task-daemon.sh --dry-run    # show what would run
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/obsidian/tasks"
LOGFILE="$WORKSPACE/obsidian/agents/cron/daemon.log"
LOCKFILE="/tmp/zion-locks/daemon.lock"

TICK_INTERVAL="${TASK_TICK_INTERVAL:-300}"
SINGLE_TICK="${TASK_SINGLE_TICK:-0}"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
RUNNER="$SCRIPT_DIR/task-runner.sh"

mkdir -p "$WORKSPACE/obsidian/agents/cron" "/tmp/zion-locks" "$TASKS/TODO" "$TASKS/DOING" "$TASKS/DONE"

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

# ── Parse date prefix ────────────────────────────────────────────
# YYYYMMDD_HH_MM_name.md → epoch seconds
card_epoch() {
  local name="$1"
  if [[ "$name" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    local y="${BASH_REMATCH[1]}" m="${BASH_REMATCH[2]}" d="${BASH_REMATCH[3]}"
    local h="${BASH_REMATCH[4]}" min="${BASH_REMATCH[5]}"
    date -d "${y}-${m}-${d} ${h}:${min}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

# ── Single tick ──────────────────────────────────────────────────
run_tick() {
  log "=== Tick ==="
  local now; now=$(date +%s)
  local threshold=$((now + 600))  # 10 min ahead
  local due=()

  for card in "$TASKS/TODO"/*.md; do
    [ -f "$card" ] || continue
    local filename; filename=$(basename "$card")
    local card_ts; card_ts=$(card_epoch "$filename")

    if [ "$card_ts" -eq 0 ]; then
      log "  skip: $filename (no date prefix)"
      continue
    fi

    if [ "$card_ts" -le "$threshold" ]; then
      due+=("$filename")
      local delta=$(( (card_ts - now) / 60 ))
      log "  due: $filename (${delta}min)"
    fi
  done

  # Also run anything stuck in DOING (recovery)
  for card in "$TASKS/DOING"/*.md; do
    [ -f "$card" ] || continue
    local filename; filename=$(basename "$card")
    local card_base; card_base=$(basename "$filename" .md)
    if [ ! -d "/tmp/zion-locks/${card_base}.lock" ]; then
      due+=("$filename")
      log "  orphan: $filename (in DOING but not locked)"
    fi
  done

  if [ ${#due[@]} -eq 0 ]; then
    log "No tasks due."
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$WORKSPACE/obsidian/agents/cron/heartbeat"
    return 0
  fi

  log "Due: ${#due[@]} tasks"

  if [ "$DRY_RUN" = "1" ]; then
    for f in "${due[@]}"; do echo "  would run: $f"; done
    return 0
  fi

  for filename in "${due[@]}"; do
    log "Running: $filename"
    "$RUNNER" "$filename" || log "  $filename finished with error"
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
  sleep "$TICK_INTERVAL"
done
