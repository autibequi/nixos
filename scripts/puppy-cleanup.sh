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

[ -d "$RUNNING_ROOT" ] || exit 0

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
