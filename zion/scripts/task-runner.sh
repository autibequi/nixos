#!/usr/bin/env bash
# task-runner.sh — Run a single task card
# Usage: task-runner.sh <filename.md>  (file must be in TODO/ or DOING/)
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/obsidian/tasks"
LOG="$TASKS/log.md"
MEMORY_DIR="$WORKSPACE/obsidian/agents/memory"
VERBOSE="${TASK_VERBOSE:-0}"
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS

CARD="${1:?Usage: task-runner.sh <card.md>}"
CARD_BASE="$(basename "$CARD" .md)"

# ── Find card ────────────────────────────────────────────────────
CARD_PATH=""
if [ -f "$TASKS/TODO/$CARD" ]; then
  CARD_PATH="$TASKS/TODO/$CARD"
elif [ -f "$TASKS/TODO/${CARD}.md" ]; then
  CARD_PATH="$TASKS/TODO/${CARD}.md"
  CARD="${CARD}.md"
elif [ -f "$TASKS/DOING/$CARD" ]; then
  CARD_PATH="$TASKS/DOING/$CARD"
elif [ -f "$TASKS/DOING/${CARD}.md" ]; then
  CARD_PATH="$TASKS/DOING/${CARD}.md"
  CARD="${CARD}.md"
else
  echo "[runner] card '$CARD' not found in TODO/ or DOING/"
  exit 1
fi

# ── Lock (atomic via mkdir) ──────────────────────────────────────
LOCKDIR="/tmp/zion-locks/${CARD_BASE}.lock"
mkdir -p "$(dirname "$LOCKDIR")"
cleanup_lock() { rm -rf "$LOCKDIR" 2>/dev/null || true; }
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCKDIR" 2>/dev/null || echo 0) ))
  MAX_AGE=$(( ${TIMEOUT:-300} + 60 ))
  if [ "$LOCK_AGE" -gt "$MAX_AGE" ]; then
    echo "[runner] '$CARD_BASE' — stale lock (${LOCK_AGE}s), clearing"
    rm -rf "$LOCKDIR"
    mkdir "$LOCKDIR"
  else
    echo "[runner] '$CARD_BASE' locked — skip (${LOCK_AGE}s old)"
    exit 0
  fi
fi
trap cleanup_lock EXIT

# ── Move to DOING ────────────────────────────────────────────────
mkdir -p "$TASKS/DOING" "$TASKS/DONE"
if [ "$(dirname "$CARD_PATH")" != "$TASKS/DOING" ]; then
  mv "$CARD_PATH" "$TASKS/DOING/$CARD"
  CARD_PATH="$TASKS/DOING/$CARD"
fi

# ── Parse frontmatter ────────────────────────────────────────────
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

extract_body() {
  local file="$1"
  [ -f "$file" ] || return
  local in_fm=0 past_fm=0
  while IFS= read -r line; do
    if [ "$past_fm" = "1" ]; then echo "$line"; continue; fi
    if [ "$line" = "---" ]; then
      if [ "$in_fm" = "1" ]; then past_fm=1; continue; fi
      in_fm=1; continue
    fi
  done < "$file"
}

# ── Config ───────────────────────────────────────────────────────
MODEL=$(parse_fm "$CARD_PATH" "model")
TIMEOUT=$(parse_fm "$CARD_PATH" "timeout")
MAX_TURNS=$(parse_fm "$CARD_PATH" "max_turns")
MCP=$(parse_fm "$CARD_PATH" "mcp")
AGENT=$(parse_fm "$CARD_PATH" "agent")

MODEL="${MODEL:-haiku}"
TIMEOUT="${TIMEOUT:-300}"
MAX_TURNS="${MAX_TURNS:-12}"
# CLI override: TASK_MAX_TURNS env var (from zion tasks run --max-turns N)
[ -n "${TASK_MAX_TURNS:-}" ] && MAX_TURNS="$TASK_MAX_TURNS"

# ── Extract task name (strip date prefix) ────────────────────────
# Format: YYYYMMDD_HH_MM_name.md → name
TASK_NAME="$CARD_BASE"
if [[ "$TASK_NAME" =~ ^[0-9]{8}_[0-9]{2}_[0-9]{2}_(.*) ]]; then
  TASK_NAME="${BASH_REMATCH[1]}"
fi

# ── Credit check (skip for scheduler — haiku, essential) ────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USAGE_SCRIPT="$SCRIPT_DIR/claude-ai-usage.sh"
if [ -x "$USAGE_SCRIPT" ] && [ "$TASK_NAME" != "scheduler" ]; then
  USAGE_JSON=$("$USAGE_SCRIPT" --json 2>/dev/null || echo "{}")
  WEEK_PCT=$(echo "$USAGE_JSON" | jq -r '
    [.weekly_limits[]? // .weeklyLimits[]? // .limits[]? // empty]
    | (.[0].percentage_used // .[0].percentageUsed // 0)
  ' 2>/dev/null || echo "0")
  WEEK_PCT="${WEEK_PCT%%.*}"  # truncate decimals
  if [ "${WEEK_PCT:-0}" -ge 70 ] 2>/dev/null; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | QUOTA_HOLD | $TASK_NAME | week=${WEEK_PCT}% | $CARD" >> "$LOG"
    echo "[runner] '$TASK_NAME' — QUOTA_HOLD (week=${WEEK_PCT}%), rescheduling +60min"
    # Move card back to TODO with +60min
    NEXT=$(date -d "+60 minutes" +%Y%m%d_%H_%M)
    mv "$CARD_PATH" "$TASKS/TODO/${NEXT}_${TASK_NAME}.md" 2>/dev/null || true
    exit 0
  fi
fi

# ── Build prompt ─────────────────────────────────────────────────
BODY=$(extract_body "$CARD_PATH")

# Load agent memory if exists
MEMORY=""
if [ -n "$AGENT" ] && [ -f "$MEMORY_DIR/${AGENT}.md" ]; then
  MEMORY=$(cat "$MEMORY_DIR/${AGENT}.md")
elif [ -f "$MEMORY_DIR/${TASK_NAME}.md" ]; then
  MEMORY=$(cat "$MEMORY_DIR/${TASK_NAME}.md")
fi

PROMPT="[HEADLESS MODE] Timeout: ${TIMEOUT}s | Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Task: $TASK_NAME | Card: $CARD | Budget: ${TIMEOUT}s

## Task card location
This card is at: $CARD_PATH
Tasks dir: $TASKS
Memory dir: $MEMORY_DIR"

if [ -n "$MEMORY" ]; then
  PROMPT="$PROMPT

## Agent Memory
$MEMORY"
fi

PROMPT="$PROMPT

## Instructions
$BODY

## Artifacts
Produce any artifacts (reports, files, outputs) in: /workspace/obsidian/artefatos/${TASK_NAME}/

## After completing
- To reschedule: move this card back to TODO/ with a new date prefix (YYYYMMDD_HH_MM_name.md)
  - YOU choose when to run next (minimum 30 minutes)
  - Prefer scheduling between 21h-06h (BRT) — agents' preferred window
  - If nothing urgent, schedule later to conserve quota
- To finish: the runner will move the card to DONE/ automatically
- Update your memory file at $MEMORY_DIR/${AGENT:-$TASK_NAME}.md if you learned something persistent"

# ── MCP config ───────────────────────────────────────────────────
MCP_FLAGS=()
if [ "$MCP" = "false" ] || [ "$MCP" = "off" ]; then
  no_mcp="/tmp/zion-no-mcp.json"
  [ -f "$no_mcp" ] || echo '{"mcpServers":{}}' > "$no_mcp"
  MCP_FLAGS=(--mcp-config "$no_mcp")
fi

# ── Log start ────────────────────────────────────────────────────
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | START | $TASK_NAME | $MODEL | $CARD" >> "$LOG"
echo "[runner] running '$TASK_NAME' (model=$MODEL, timeout=${TIMEOUT}s, turns=$MAX_TURNS)"

# ── Run ──────────────────────────────────────────────────────────
LOGDIR="$WORKSPACE/obsidian/agents/cron/runs/$TASK_NAME"
mkdir -p "$LOGDIR"
# Fix dirs criados como root por execuções anteriores sem -u claude
if [ ! -w "$LOGDIR" ]; then
  chmod 755 "$LOGDIR" 2>/dev/null || true
  # Se ainda não tem acesso, usar /tmp como fallback
  LOGDIR="/tmp/zion-runs/$TASK_NAME"
  mkdir -p "$LOGDIR"
fi
LOGFILE="$LOGDIR/$(date +%Y-%m-%d_%H-%M).log"

START_S=$SECONDS

CLAUDE_ARGS=(
  --permission-mode bypassPermissions
  --model "$MODEL"
  --max-turns "$MAX_TURNS"
)
[ ${#MCP_FLAGS[@]} -gt 0 ] && CLAUDE_ARGS+=("${MCP_FLAGS[@]}")
CLAUDE_ARGS+=(-p "$PROMPT")

EXIT_CODE=0
HEADLESS=1 PUPPY_TIMEOUT="$TIMEOUT" \
timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" 2>&1 | tee "$LOGFILE" || true
EXIT_CODE=${PIPESTATUS[0]}
ELAPSED=$((SECONDS - START_S))

STATUS="ok"
[ "$EXIT_CODE" -eq 124 ] && STATUS="timeout"
[ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 124 ] && STATUS="fail"

# ── Finish ───────────────────────────────────────────────────────
ELAPSED_FMT="$((ELAPSED/60))m$((ELAPSED%60))s"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $STATUS | $TASK_NAME | $MODEL | ${ELAPSED_FMT} | exit=$EXIT_CODE | $CARD" >> "$LOG"

if [ "$STATUS" != "ok" ]; then
  echo "[runner] '$TASK_NAME' — $STATUS (exit=$EXIT_CODE, ${ELAPSED_FMT})"
  echo "[runner] log: $LOGFILE"
  echo "[runner] --- last 20 lines ---"
  tail -20 "$LOGFILE" 2>/dev/null || true
  echo "[runner] ---"
fi

# If agent moved card back to TODO (rescheduled itself), we're done
if [ ! -f "$CARD_PATH" ]; then
  echo "[runner] '$TASK_NAME' — rescheduled (${ELAPSED_FMT})"
  exit 0
fi

# Otherwise move to DONE
mv "$CARD_PATH" "$TASKS/DONE/$CARD" 2>/dev/null || true
echo "[runner] '$TASK_NAME' → DONE ($STATUS, ${ELAPSED_FMT})"
