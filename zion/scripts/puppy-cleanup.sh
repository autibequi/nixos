#!/usr/bin/env bash
# =============================================================================
# puppy-cleanup.sh — Clean stuck Puppy tasks and locks
# =============================================================================
# Uses SCHEDULER_VAULT_DIR and SCHEDULER_PROJECT_DIR (or PROJECT_DIR). Safe to run on
# host (Nix ExecStopPost) or inside scheduler container.
# =============================================================================
set -euo pipefail

PROJECT_DIR="${SCHEDULER_PROJECT_DIR:-${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}}"
VAULT_DIR="${SCHEDULER_VAULT_DIR:-${HOME:-/tmp}/.ovault/Work}"

RUNNING_ROOT="${VAULT_DIR}/tasks/doing"
PENDING_ROOT="${VAULT_DIR}/tasks/backlog"
EPHEMERAL="${PROJECT_DIR}/.ephemeral"
WORKSPACE="${WORKSPACE:-/workspace}"
CRON_RUNS_DIR="${WORKSPACE}/obsidian/agents/cron/runs"

[ -d "$RUNNING_ROOT" ] || exit 0

# ─────────────────────────────────────────────────────────────────
# Log rotation: keep only 10 most recent logs per task directory
# ─────────────────────────────────────────────────────────────────
rotate_cron_logs() {
  [ -d "$CRON_RUNS_DIR" ] || return 0

  local rotated_count=0
  for task_dir in "$CRON_RUNS_DIR"/*/; do
    [ -d "$task_dir" ] || continue
    local task_name
    task_name=$(basename "$task_dir")

    # Count logs
    local log_count
    log_count=$(find "$task_dir" -maxdepth 1 -name "*.log" -type f 2>/dev/null | wc -l)
    [ "$log_count" -le 10 ] && continue

    # Keep 10 most recent, delete older ones
    local to_delete
    to_delete=$((log_count - 10))
    find "$task_dir" -maxdepth 1 -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | \
      sort -n | head -n "$to_delete" | cut -d' ' -f2- | while read -r log; do
        rm -f "$log"
        rotated_count=$((rotated_count + 1))
      done

    [ "$to_delete" -gt 0 ] && echo "[cleanup] $task_name: rotated $to_delete logs (kept 10)"
  done

  [ "$rotated_count" -gt 0 ] && echo "[cleanup] Rotated $rotated_count cron logs total"
}

for dir in "$RUNNING_ROOT"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
  rm -f "$dir/.lock"
  if [ "$source" = "recurring" ]; then
    rm -rf "$dir"
    echo "[cleanup] $name (recurring) removed"
  else
    mkdir -p "$PENDING_ROOT"
    mv "$dir" "$PENDING_ROOT/$name" 2>/dev/null || rm -rf "$dir"
    echo "[cleanup] $name → pending/"
  fi
done

rm -f "${EPHEMERAL}/.kanban.lock" "${EPHEMERAL}"/locks/*.lock 2>/dev/null || true

# Rotate cron logs (keep 10 per task)
rotate_cron_logs
