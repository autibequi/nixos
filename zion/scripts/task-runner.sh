#!/usr/bin/env bash
# task-runner.sh — Run a single task (one-shot or recurring cycle)
# Usage: task-runner.sh <task-name> <source>
#   source: _scheduled | backlog
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/obsidian/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
STATE_FILE="${TASK_STATE_FILE:-$WORKSPACE/obsidian/agents/cron/state.json}"
MURAL="$WORKSPACE/obsidian/MURAL.md"
TASK_LOG="$WORKSPACE/obsidian/agents/task.log.md"
VERBOSE="${TASK_VERBOSE:-0}"

TASK_NAME="${1:?Usage: task-runner.sh <task> <source>}"
SOURCE="${2:-backlog}"

DEFAULT_TIMEOUT=300
DEFAULT_MODEL="haiku"
DEFAULT_MAX_TURNS=12
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS

mkdir -p "$EPHEMERAL/locks" "$TASKS/doing" "$TASKS/done" "$TASKS/cancelled"

# ── Lock (atomic via mkdir) ──────────────────────────────────────
LOCKDIR="$EPHEMERAL/locks/${TASK_NAME}.lock"
cleanup_lock() { rm -rf "$LOCKDIR" 2>/dev/null || true; }
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  echo "[task-runner] '$TASK_NAME' locked — skip"
  exit 0
fi
trap cleanup_lock EXIT

# ── Locate task ──────────────────────────────────────────────────
TASK_SRC="$TASKS/$SOURCE/$TASK_NAME"
[ -d "$TASK_SRC" ] || { echo "[task-runner] '$TASK_NAME' not found in $SOURCE/"; exit 1; }

task_file() {
  if [ -f "$1/TASK.md" ]; then echo "$1/TASK.md"
  elif [ -f "$1/CLAUDE.md" ]; then echo "$1/CLAUDE.md"
  else echo ""; fi
}

CONFIG=$(task_file "$TASK_SRC")
[ -n "$CONFIG" ] || { echo "[task-runner] '$TASK_NAME' has no TASK.md or CLAUDE.md"; exit 1; }

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

# Extract tags from frontmatter (supports: tags: [a, b, c] or tags: [a,b,c])
parse_tags() {
  local file="$1"
  parse_fm "$file" "tags" | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# ── Resolve template ─────────────────────────────────────────────
TEMPLATE_NAME=$(parse_fm "$CONFIG" "template")
TEMPLATE_FILE=""
TEMPLATE_BODY=""
if [ -n "$TEMPLATE_NAME" ]; then
  TEMPLATE_FILE="$TASKS/templates/${TEMPLATE_NAME}.md"
  [ -f "$TEMPLATE_FILE" ] || { echo "[task-runner] template '$TEMPLATE_NAME' not found"; TEMPLATE_FILE=""; }
fi

# ── Merge config (task overrides template) ───────────────────────
resolve() {
  local key="$1" default="$2"
  local val=""
  val=$(parse_fm "$CONFIG" "$key")
  if [ -z "$val" ] && [ -n "$TEMPLATE_FILE" ]; then
    val=$(parse_fm "$TEMPLATE_FILE" "$key")
  fi
  echo "${val:-$default}"
}

TIMEOUT=$(resolve "timeout" "$DEFAULT_TIMEOUT")
MODEL="haiku"
MAX_TURNS="$DEFAULT_MAX_TURNS"
MCP_OFF=0

# Collect tags from both template and task (union)
ALL_TAGS=""
[ -n "$TEMPLATE_FILE" ] && ALL_TAGS=$(parse_tags "$TEMPLATE_FILE")
ALL_TAGS=$(printf '%s\n%s' "$ALL_TAGS" "$(parse_tags "$CONFIG")" | sort -u | grep -v '^$' || true)

# Process tags
while IFS= read -r tag; do
  [ -z "$tag" ] && continue
  case "$tag" in
    model/haiku)  MODEL="haiku" ;;
    model/sonnet) MODEL="sonnet" ;;
    model/opus)   MODEL="opus" ;;
    mcp/off)      MCP_OFF=1 ;;
    turns/*)      MAX_TURNS="${tag#turns/}" ;;
    *)            ;; # other tags are informational
  esac
done <<< "$ALL_TAGS"

# Direct frontmatter model/max_turns override tags (backward compat)
FM_MODEL=$(parse_fm "$CONFIG" "model")
[ -n "$FM_MODEL" ] && MODEL="$FM_MODEL"
FM_TURNS=$(parse_fm "$CONFIG" "max_turns")
[ -n "$FM_TURNS" ] && MAX_TURNS="$FM_TURNS"

# MCP backward compat
FM_MCP=$(parse_fm "$CONFIG" "mcp")
[ "$FM_MCP" = "false" ] && MCP_OFF=1

# ── Build prompt ─────────────────────────────────────────────────
# Template body = everything after frontmatter
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

TEMPLATE_BODY=""
[ -n "$TEMPLATE_FILE" ] && TEMPLATE_BODY=$(extract_body "$TEMPLATE_FILE")
TASK_BODY=$(extract_body "$CONFIG")

PROMPT=""
[ -n "$TEMPLATE_BODY" ] && PROMPT="$TEMPLATE_BODY

---

"
PROMPT="${PROMPT}${TASK_BODY}"

# ── Claim (copy for recurring, move for one-shot) ────────────────
IS_RECURRING=0
[ "$SOURCE" = "_scheduled" ] && IS_RECURRING=1

if [ "$IS_RECURRING" = "1" ]; then
  cp -r "$TASK_SRC" "$TASKS/doing/$TASK_NAME" 2>/dev/null || { echo "[task-runner] claim failed"; exit 1; }
else
  mv "$TASK_SRC" "$TASKS/doing/$TASK_NAME" 2>/dev/null || { echo "[task-runner] claim failed"; exit 1; }
fi

echo "[task-runner] '$TASK_NAME' claimed (model=$MODEL, timeout=${TIMEOUT}s, turns=$MAX_TURNS, mcp=$([ $MCP_OFF = 1 ] && echo off || echo on))"

# ── MCP config ───────────────────────────────────────────────────
MCP_FLAGS=()
if [ "$MCP_OFF" = "1" ]; then
  [ -f "$EPHEMERAL/no-mcp.json" ] || echo '{"mcpServers":{}}' > "$EPHEMERAL/no-mcp.json"
  MCP_FLAGS=(--mcp-config "$EPHEMERAL/no-mcp.json")
fi

# ── Log start ────────────────────────────────────────────────────
echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $TASK_NAME | start | $MODEL | — |" >> "$TASK_LOG" 2>/dev/null || true

# ── Invoke Claude ────────────────────────────────────────────────
LOGDIR="$WORKSPACE/obsidian/agents/cron/runs/$TASK_NAME"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/$(date +%Y-%m-%d_%H-%M).log"

TASK_TYPE="ONE-SHOT"
[ "$IS_RECURRING" = "1" ] && TASK_TYPE="RECURRING"

FULL_PROMPT="[HEADLESS MODE] Timeout: ${TIMEOUT}s | Deadline: $(date -u -d "+${TIMEOUT} seconds" +%H:%M:%S 2>/dev/null || echo "${TIMEOUT}s from now")

Task: $TASK_NAME | Type: $TASK_TYPE | Dir: $TASKS/doing/$TASK_NAME
Context: $EPHEMERAL/notes/$TASK_NAME | MURAL: $MURAL
Time: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Budget: ${TIMEOUT}s

$PROMPT"

START_S=$SECONDS
EXIT_CODE=0

CLAUDE_ARGS=(
  --permission-mode bypassPermissions
  --model "$MODEL"
  --max-turns "$MAX_TURNS"
)
[ ${#MCP_FLAGS[@]} -gt 0 ] && CLAUDE_ARGS+=("${MCP_FLAGS[@]}")
CLAUDE_ARGS+=(-p "$FULL_PROMPT")

HEADLESS=1 PUPPY_TIMEOUT="$TIMEOUT" \
timeout "$TIMEOUT" claude "${CLAUDE_ARGS[@]}" 2>&1 | \
  if [ "$VERBOSE" = "1" ]; then tee "$LOGFILE"; else cat > "$LOGFILE"; fi || true
EXIT_CODE=${PIPESTATUS[0]}
ELAPSED=$((SECONDS - START_S))

[ "$EXIT_CODE" -eq 0 ] && echo "[task-runner] '$TASK_NAME' OK (${ELAPSED}s)" || echo "[task-runner] '$TASK_NAME' FAIL exit=$EXIT_CODE (${ELAPSED}s)"

# ── Finish ───────────────────────────────────────────────────────
STATUS="ok"; [ "$EXIT_CODE" -ne 0 ] && STATUS="fail"; [ "$EXIT_CODE" -eq 124 ] && STATUS="timeout"
ICON="done"; [ "$EXIT_CODE" -ne 0 ] && ICON="cancelled"

if [ "$IS_RECURRING" = "1" ]; then
  # Sync evolved files back to _scheduled
  for f in memoria.md TASK.md CLAUDE.md; do
    [ -f "$TASKS/doing/$TASK_NAME/$f" ] && cp "$TASKS/doing/$TASK_NAME/$f" "$TASKS/_scheduled/$TASK_NAME/$f" 2>/dev/null || true
  done
  rm -rf "$TASKS/doing/$TASK_NAME"
  echo "[task-runner] '$TASK_NAME' cycle done"
elif [ "$EXIT_CODE" -eq 0 ]; then
  mv "$TASKS/doing/$TASK_NAME" "$TASKS/done/$TASK_NAME" 2>/dev/null || true
  echo "[task-runner] '$TASK_NAME' -> done"
else
  mv "$TASKS/doing/$TASK_NAME" "$TASKS/cancelled/$TASK_NAME" 2>/dev/null || true
  echo "[task-runner] '$TASK_NAME' -> cancelled ($STATUS)"
fi

# Log completion
ELAPSED_FMT="$((ELAPSED/60))m$((ELAPSED%60))s"
echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $TASK_NAME | $ICON | $MODEL | $ELAPSED_FMT |" >> "$TASK_LOG" 2>/dev/null || true

# ── Update state.json ────────────────────────────────────────────
mkdir -p "$(dirname "$STATE_FILE")"
python3 -c "
import json, time, os
f = '$STATE_FILE'
try:
    s = json.load(open(f))
except:
    s = {'last_tick': '', 'tasks': {}}
t = s.setdefault('tasks', {}).setdefault('$TASK_NAME', {
    'last_run': 0, 'last_status': '', 'last_duration_s': 0,
    'avg_duration_s': 0, 'runs_total': 0, 'runs_failed': 0
})
t['last_run'] = int(time.time())
t['last_status'] = '$STATUS'
t['last_duration_s'] = $ELAPSED
old_avg = t.get('avg_duration_s', 0)
t['avg_duration_s'] = round(0.3 * $ELAPSED + 0.7 * old_avg) if old_avg > 0 else $ELAPSED
t['runs_total'] = t.get('runs_total', 0) + 1
if '$STATUS' != 'ok':
    t['runs_failed'] = t.get('runs_failed', 0) + 1
s['last_tick'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
json.dump(s, open(f, 'w'), indent=2)
" 2>/dev/null || true

# Regenerate STATUS.md
STATUS_SCRIPT="$(dirname "$(readlink -f "$0")")/puppy-status.sh"
[ -x "$STATUS_SCRIPT" ] && "$STATUS_SCRIPT" 2>/dev/null || true
