#!/usr/bin/env bash
# task-runner.sh — Run a single task card
# Usage: task-runner.sh <filename.md>  (file must be in bedrooms/_waiting/ or bedrooms/_working/)
set -euo pipefail

# Se rodando como root, re-exec como uid 1000 (claude) para evitar arquivos root-owned nos volumes
if [ "$(id -u)" = "0" ]; then
  exec setpriv --reuid=1000 --regid=1000 --keep-groups \
    env USER=claude LOGNAME=claude HOME=/home/claude \
    "$0" "$@"
fi

WORKSPACE="/workspace"
OBSIDIAN="${OBSIDIAN_PATH:-$WORKSPACE/obsidian}"
CONTRACTORS_DIR="${TASK_CONTRACTORS_DIR:-$OBSIDIAN/bedrooms}"
SCHEDULE_DIR="${SCHEDULE_DIR:-$OBSIDIAN/bedrooms/_waiting}"
VERBOSE="${TASK_VERBOSE:-0}"
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS

CARD="${1:?Usage: task-runner.sh <card.md>}"
CARD_BASE="$(basename "$CARD" .md)"

# ── Find card ────────────────────────────────────────────────────
RUNNING_DIR="${RUNNING_DIR:-$OBSIDIAN/bedrooms/_working}"
CARD_PATH=""
if [ -f "$SCHEDULE_DIR/$CARD" ]; then
  CARD_PATH="$SCHEDULE_DIR/$CARD"
elif [ -f "$SCHEDULE_DIR/${CARD}.md" ]; then
  CARD_PATH="$SCHEDULE_DIR/${CARD}.md"
  CARD="${CARD}.md"
elif [ -f "$RUNNING_DIR/$CARD" ]; then
  CARD_PATH="$RUNNING_DIR/$CARD"
elif [ -f "$RUNNING_DIR/${CARD}.md" ]; then
  CARD_PATH="$RUNNING_DIR/${CARD}.md"
  CARD="${CARD}.md"
else
  echo "[runner] card '$CARD' not found in bedrooms/_waiting/ or bedrooms/_working/"
  exit 1
fi

# ── Lock (atomic via mkdir) ──────────────────────────────────────
LOCKDIR="/tmp/leech-locks/${CARD_BASE}.lock"
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

# ── Move to _running ───────────────────────────────────────────────
mkdir -p "$RUNNING_DIR"
if [ "$(dirname "$CARD_PATH")" != "$RUNNING_DIR" ]; then
  mv "$CARD_PATH" "$RUNNING_DIR/$CARD"
  CARD_PATH="$RUNNING_DIR/$CARD"
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
AGENT=$(parse_fm "$CARD_PATH" "contractor")
[ -z "$AGENT" ] && AGENT=$(parse_fm "$CARD_PATH" "agent")

MODEL="${MODEL:-haiku}"
TIMEOUT="${TIMEOUT:-1800}"
MAX_TURNS="${MAX_TURNS:-12}"
# CLI override: TASK_MAX_TURNS env var (from yaa tasks run --max-turns N)
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
if [ -x "$USAGE_SCRIPT" ] && [ "$TASK_NAME" != "hermes" ]; then
  USAGE_JSON=$("$USAGE_SCRIPT" --json 2>/dev/null || echo "{}")
  WEEK_PCT=$(echo "$USAGE_JSON" | jq -r '
    [.weekly_limits[]? // .weeklyLimits[]? // .limits[]? // empty]
    | (.[0].percentage_used // .[0].percentageUsed // 0)
  ' 2>/dev/null || echo "0")
  WEEK_PCT="${WEEK_PCT%%.*}"  # truncate decimals
  if [ "${WEEK_PCT:-0}" -ge 70 ] 2>/dev/null; then
    echo "[runner] '$TASK_NAME' — QUOTA_HOLD (week=${WEEK_PCT}%), rescheduling +60min"
    # Move card back to _schedule with +60min
    NEXT=$(date -d "+60 minutes" +%Y%m%d_%H_%M)
    mv "$CARD_PATH" "$SCHEDULE_DIR/${NEXT}_${TASK_NAME}.md" 2>/dev/null || true
    exit 0
  fi
fi

# ── Build prompt ─────────────────────────────────────────────────
BODY=$(extract_body "$CARD_PATH")

# Load agent memory if exists
MEMORY=""
if [ -n "$AGENT" ] && [ -f "$CONTRACTORS_DIR/${AGENT}/memory.md" ]; then
  MEMORY=$(cat "$CONTRACTORS_DIR/${AGENT}/memory.md")
elif [ -f "$CONTRACTORS_DIR/${TASK_NAME}/memory.md" ]; then
  MEMORY=$(cat "$CONTRACTORS_DIR/${TASK_NAME}/memory.md")
fi

# Determine artifacts path
if [ -n "$AGENT" ]; then
  ARTIFACTS_DIR="$CONTRACTORS_DIR/${AGENT}/outputs/"
else
  ARTIFACTS_DIR="$CONTRACTORS_DIR/${TASK_NAME}/outputs/"
fi

PROMPT="[HEADLESS MODE] Timeout: ${TIMEOUT}s | Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Task: $TASK_NAME | Card: $CARD | Budget: ${TIMEOUT}s

## Task card location
This card is at: $CARD_PATH
Schedule dir: $SCHEDULE_DIR
Contractors dir: $CONTRACTORS_DIR"

if [ -n "$MEMORY" ]; then
  PROMPT="$PROMPT

## Agent Memory
$MEMORY"
fi

PROMPT="$PROMPT

## Instructions
$BODY

## Artifacts
Produce any artifacts (reports, files, outputs) in: $ARTIFACTS_DIR

## After completing
- To reschedule: move this card back to bedrooms/_waiting/ with a new date prefix (YYYYMMDD_HH_MM_name.md)
  - Path: $SCHEDULE_DIR/
  - YOU choose when to run next (minimum 30 minutes)
  - Prefer scheduling between 21h-06h (BRT) — agents' preferred window
  - If nothing urgent, schedule later to conserve quota
- To finish: the runner will move the card to your done/ folder automatically
- Update your memory file at $CONTRACTORS_DIR/${AGENT:-$TASK_NAME}/memory.md if you learned something persistent"

# ── MCP config ───────────────────────────────────────────────────
MCP_FLAGS=()
if [ "$MCP" = "false" ] || [ "$MCP" = "off" ]; then
  no_mcp="/tmp/leech-no-mcp.json"
  [ -f "$no_mcp" ] || echo '{"mcpServers":{}}' > "$no_mcp"
  MCP_FLAGS=(--mcp-config "$no_mcp")
fi

# ── Log start ────────────────────────────────────────────────────
RUN_START_FMT=$(date -u +"%H:%M:%S UTC")
echo "[runner] running '$TASK_NAME' (model=$MODEL, timeout=${TIMEOUT}s, turns=$MAX_TURNS, start=$RUN_START_FMT)"

# ── Run ──────────────────────────────────────────────────────────
LOGDIR="$OBSIDIAN/.ephemeral/cron-logs/$TASK_NAME"
mkdir -p "$LOGDIR"
# Fix dirs criados como root por execuções anteriores sem -u claude
if [ ! -w "$LOGDIR" ]; then
  chmod 755 "$LOGDIR" 2>/dev/null || true
  # Se ainda não tem acesso, usar /tmp como fallback
  LOGDIR="/tmp/leech-runs/$TASK_NAME"
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
cd "$HOME"
HEADLESS=1 \
timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" --add-dir "$HOME" 2>&1 | tee "$LOGFILE" || true
EXIT_CODE=${PIPESTATUS[0]}
ELAPSED=$((SECONDS - START_S))

STATUS="ok"
[ "$EXIT_CODE" -eq 124 ] && STATUS="timeout"
[ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 124 ] && STATUS="fail"

# ── Token usage (best-effort parse from log) ─────────────────────
if [ -f "$LOGFILE" ]; then
  TOK_IN=$(grep -oiE '"input_tokens":[[:space:]]*[0-9]+' "$LOGFILE" | tail -1 | grep -oE '[0-9]+' || true)
  TOK_OUT=$(grep -oiE '"output_tokens":[[:space:]]*[0-9]+' "$LOGFILE" | tail -1 | grep -oE '[0-9]+' || true)
  TOK_CACHE=$(grep -oiE '"cache_read_input_tokens":[[:space:]]*[0-9]+' "$LOGFILE" | tail -1 | grep -oE '[0-9]+' || true)
  if [ -n "$TOK_IN" ] || [ -n "$TOK_OUT" ]; then
    echo "  ┌─ usage ──────────────────────────────┐"
    printf "  │  in=%-8s  out=%-8s  cache=%s\n" "${TOK_IN:-?}" "${TOK_OUT:-?}" "${TOK_CACHE:-?}"
    echo "  └──────────────────────────────────────┘"
  fi
fi

# ── Finish ───────────────────────────────────────────────────────
ELAPSED_FMT="$((ELAPSED/60))m$((ELAPSED%60))s"
RUN_END_FMT=$(date -u +"%H:%M:%S UTC")

if [ "$STATUS" != "ok" ]; then
  echo "[runner] '$TASK_NAME' — $STATUS (exit=$EXIT_CODE, ${ELAPSED_FMT})"
  echo "[runner] log: $LOGFILE"
  echo "[runner] --- last 20 lines ---"
  tail -20 "$LOGFILE" 2>/dev/null || true
  echo "[runner] ---"
fi

# If agent moved card back to _schedule (rescheduled itself), we're done
DONE_AGENT="${AGENT:-$TASK_NAME}"
_write_activity_log() {
  local agent="$1"
  local log_file="$OBSIDIAN/vault/logs/agents.md"
  mkdir -p "$(dirname "$log_file")"
  local tok_str="in=${TOK_IN:-0} out=${TOK_OUT:-0}"
  [ -n "$TOK_CACHE" ] && tok_str+=" cache=${TOK_CACHE}"
  local card_label="${CARD%.md}"
  printf "| %s | %s | %s | %s | %s | %s |\n" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$agent" \
    "$STATUS" \
    "$ELAPSED_FMT" \
    "$tok_str" \
    "$card_label" \
    >> "$log_file"
}

if [ ! -f "$CARD_PATH" ]; then
  _write_activity_log "$DONE_AGENT"
  echo "[runner] '$TASK_NAME' — rescheduled (${RUN_START_FMT} → ${RUN_END_FMT}, ${ELAPSED_FMT})"
  exit 0
fi

# Otherwise move to contractor's done/ folder
DONE_DIR="$CONTRACTORS_DIR/${DONE_AGENT}/done"
mkdir -p "$DONE_DIR"
mv "$CARD_PATH" "$DONE_DIR/$CARD" 2>/dev/null || true
_write_activity_log "$DONE_AGENT"
echo "[runner] '$TASK_NAME' → ${DONE_AGENT}/done/ ($STATUS, ${RUN_START_FMT} → ${RUN_END_FMT}, ${ELAPSED_FMT})"
