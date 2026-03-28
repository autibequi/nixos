#!/usr/bin/env bash
# =============================================================================
# scheduler-dashboard.sh — Visual dashboard for CLAUDINHO unified scheduler
# =============================================================================
# Reads .ephemeral/scheduler/state.json + recurring task configs
# Outputs a compact table for terminal/bootstrap display
# =============================================================================
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
[ -d "$WORKSPACE" ] || WORKSPACE="$(cd "$(dirname "$0")/../../.." && pwd)"
STATE_FILE="$WORKSPACE/.ephemeral/scheduler/state.json"
TASKS_DIR="$WORKSPACE/obsidian/_agent/tasks/recurring"
DASHBOARD_FILE="$WORKSPACE/.ephemeral/scheduler/dashboard.txt"

# ── Colors ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD="\033[1m"; DIM="\033[2m"; RESET="\033[0m"
  RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; CYAN="\033[36m"
else
  BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; CYAN=""
fi

# ── Parse frontmatter ───────────────────────────────────────────────────────
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

clock_to_interval() {
  case "$1" in
    every10)  echo 10 ;;
    every60)  echo 60 ;;
    every240) echo 240 ;;
    *)        echo 60 ;;
  esac
}

get_interval() {
  local task_dir="$1"
  local interval
  interval=$(parse_fm "$task_dir/CLAUDE.md" "interval")
  if [ -n "$interval" ]; then echo "$interval"; return; fi
  local clock_val
  clock_val=$(parse_fm "$task_dir/CLAUDE.md" "clock")
  clock_to_interval "${clock_val:-every60}"
}

# ── State reader ─────────────────────────────────────────────────────────────
get_state_field() {
  local task="$1" field="$2"
  [ -f "$STATE_FILE" ] || return
  python3 -c "
import json
try:
    s = json.load(open('$STATE_FILE'))
    v = s.get('tasks', {}).get('$task', {}).get('$field', '')
    print(v if v != '' else '')
except: pass
" 2>/dev/null
}

get_last_tick() {
  [ -f "$STATE_FILE" ] || return
  python3 -c "
import json
try:
    s = json.load(open('$STATE_FILE'))
    print(s.get('last_tick', ''))
except: pass
" 2>/dev/null
}

# ── Build dashboard ──────────────────────────────────────────────────────────
now=$(date +%s)
last_tick=$(get_last_tick)

# Calculate next tick (rough: last_tick + 600s)
next_tick_label="--:--"
if [ -n "$last_tick" ]; then
  last_ts=$(date -d "$last_tick" +%s 2>/dev/null || echo 0)
  next_ts=$((last_ts + 600))
  if [ "$next_ts" -gt "$now" ]; then
    next_tick_label="$(date -d "@$next_ts" +%H:%M)"
  else
    next_tick_label="NOW"
  fi
fi

# Collect task data
declare -a rows=()
total_daily_tokens=0
budget_used=0

if [ -d "$TASKS_DIR" ]; then
  for dir in "$TASKS_DIR"/*/; do
    [ -d "$dir" ] || continue
    [ -f "$dir/CLAUDE.md" ] || continue
    task=$(basename "$dir")

    interval=$(get_interval "$dir")
    model=$(parse_fm "$dir/CLAUDE.md" "model")
    model="${model:-haiku}"
    timeout_val=$(parse_fm "$dir/CLAUDE.md" "timeout")
    timeout_val="${timeout_val:-300}"

    avg=$(get_state_field "$task" "avg_duration_s")
    avg="${avg:-?}"
    last_run=$(get_state_field "$task" "last_run")
    last_run="${last_run:-0}"
    last_status=$(get_state_field "$task" "last_status")
    runs_total=$(get_state_field "$task" "runs_total")
    runs_failed=$(get_state_field "$task" "runs_failed")

    # Calculate "Next" in minutes
    next_label="?"
    if [ "$last_run" != "0" ] && [ "$last_run" != "" ]; then
      interval_s=$((interval * 60))
      due_at=$((last_run + interval_s))
      if [ "$now" -ge "$due_at" ]; then
        next_label="${YELLOW}★DUE${RESET}"
        indicator="●"
      else
        remaining=$(( (due_at - now + 59) / 60 ))  # ceil to minutes
        if [ "$remaining" -le 15 ]; then
          next_label="${remaining}m"
          indicator="○"
        else
          next_label="${remaining}m"
          indicator="◌"
        fi
      fi
    else
      next_label="${YELLOW}★DUE${RESET}"
      indicator="●"
    fi

    # Estimate daily tokens (rough: runs_per_day × avg_tokens)
    runs_per_day=$(( 1440 / interval ))
    # Rough token estimate per model
    case "$model" in
      haiku)  tok_per_run=38000 ;;
      sonnet) tok_per_run=52000 ;;
      opus)   tok_per_run=80000 ;;
      *)      tok_per_run=40000 ;;
    esac
    daily_tok=$((runs_per_day * tok_per_run))
    daily_tok_m=$(python3 -c "print(f'{$daily_tok/1000000:.1f}')" 2>/dev/null || echo "?")
    total_daily_tokens=$((total_daily_tokens + daily_tok))

    rows+=("${indicator}|${task}|${interval}m|${model}|${avg}s|${next_label}|${daily_tok_m}M")
  done
fi

total_daily_m=$(python3 -c "print(f'{$total_daily_tokens/1000000:.1f}')" 2>/dev/null || echo "?")
quota_daily="9.2"
pace=$(python3 -c "
d = $total_daily_tokens / 1000000
q = $quota_daily
print(f'{d/q:.1f}x' if q > 0 else '?')
" 2>/dev/null || echo "?")

# ── Render ───────────────────────────────────────────────────────────────────
{
  tick_label=$([ -n "$last_tick" ] && date -d "$last_tick" +%H:%M 2>/dev/null || echo "--:--")

  echo -e "┌─ ${BOLD}Scheduler${RESET} ─────────────────────────────────────────────────────┐"
  echo -e "│ Tick: ${CYAN}${tick_label}${RESET} │ Budget: ${TICK_BUDGET:-540}s │ Next: ${CYAN}${next_tick_label}${RESET}$(printf '%*s' 17 '')│"
  echo -e "├─────────────────────┬──────┬────────┬────────┬──────┬──────────┤"
  echo -e "│ Task                │  ⏱   │ Model  │ Avg    │ Next │ Tok/day  │"
  echo -e "├─────────────────────┼──────┼────────┼────────┼──────┼──────────┤"

  # Sort rows by interval (P0 first)
  IFS=$'\n' sorted=($(printf '%s\n' "${rows[@]}" | sort -t'|' -k3,3n))

  for row in "${sorted[@]}"; do
    IFS='|' read -r ind name intv mdl avg nxt tok <<< "$row"
    printf "│ %s %-18s │ %4s │ %-6s │ %5s │ %4s │ %6s   │\n" \
      "$ind" "$name" "$intv" "$mdl" "$avg" "$nxt" "$tok"
  done

  echo -e "├─────────────────────┴──────┴────────┴────────┴──────┴──────────┤"

  pace_color="$GREEN"
  [ "$(echo "$pace" | tr -d 'x')" != "?" ] && \
    python3 -c "exit(0 if float('${pace%x}') <= 1.0 else 1)" 2>/dev/null || pace_color="$RED"

  echo -e "│ Daily: ~${total_daily_m}M tok │ Quota: 275M/30d (${quota_daily}M/d) │ Pace: ${pace_color}${pace}${RESET}$(printf '%*s' 5 '')│"
  echo -e "└─────────────────────────────────────────────────────────────────┘"
} | tee "$DASHBOARD_FILE" 2>/dev/null || true
