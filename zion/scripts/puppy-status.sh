#!/usr/bin/env bash
# =============================================================================
# puppy-status.sh — Generate STATUS.md in Obsidian agents/cron/
# =============================================================================
# Called after each task run to update the cron health dashboard.
# =============================================================================
set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
VAULT_DIR="${VAULT_DIR:-$WORKSPACE/obsidian}"
CRON_DIR="$VAULT_DIR/agents/cron"
STATE_FILE="$CRON_DIR/state.json"
STATUS_FILE="$CRON_DIR/STATUS.md"
RUNS_DIR="$CRON_DIR/runs"

mkdir -p "$CRON_DIR"

# ── Read state.json ───────────────────────────────────────────────────────────
if [ ! -f "$STATE_FILE" ]; then
  echo "# Cron Status" > "$STATUS_FILE"
  echo "> state.json não encontrado — daemon ainda não rodou." >> "$STATUS_FILE"
  exit 0
fi

# ── Heartbeat ────────────────────────────────────────────────────────────────
HEARTBEAT_FILE="$CRON_DIR/heartbeat"
heartbeat_age="desconhecido"
if [ -f "$HEARTBEAT_FILE" ]; then
  last_hb=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo "")
  if [ -n "$last_hb" ]; then
    last_ts=$(date -d "$last_hb" +%s 2>/dev/null || echo "0")
    now_ts=$(date +%s)
    age_s=$(( now_ts - last_ts ))
    if [ "$age_s" -lt 60 ]; then
      heartbeat_age="há ${age_s}s"
    elif [ "$age_s" -lt 3600 ]; then
      heartbeat_age="há $((age_s / 60))min"
    else
      heartbeat_age="há $((age_s / 3600))h"
    fi
  fi
fi

# ── Generate STATUS.md via python3 ───────────────────────────────────────────
python3 - "$STATE_FILE" "$STATUS_FILE" "$RUNS_DIR" "$heartbeat_age" <<'PYEOF'
import json, sys, os, glob
from datetime import datetime, timezone

state_file, status_file, runs_dir, heartbeat_age = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(state_file) as f:
    state = json.load(f)

tasks = state.get("tasks", {})
now_ts = datetime.now(timezone.utc).timestamp()

# Compute overall success rate (7d window)
total_runs = sum(t.get("runs_total", 0) for t in tasks.values())
total_failed = sum(t.get("runs_failed", 0) for t in tasks.values())
success_rate = round(100 * (total_runs - total_failed) / total_runs) if total_runs > 0 else 100

# Build tasks table
task_rows = []
for name, t in sorted(tasks.items()):
    last_run_ts = t.get("last_run", 0)
    if last_run_ts > 0:
        age_s = int(now_ts - last_run_ts)
        if age_s < 60:
            last_run_str = f"há {age_s}s"
        elif age_s < 3600:
            last_run_str = f"há {age_s // 60}min"
        else:
            last_run_str = f"há {age_s // 3600}h"
    else:
        last_run_str = "nunca"

    status = t.get("last_status", "?")
    icon = "✅" if status == "ok" else ("⏱️" if status == "timeout" else "❌")
    duration = t.get("last_duration_s", 0)
    avg = t.get("avg_duration_s", 0)
    runs = t.get("runs_total", 0)
    failed = t.get("runs_failed", 0)

    task_rows.append(f"| {name} | {last_run_str} | {icon} {status} | {duration}s | {avg}s avg | {runs} runs / {failed} fail |")

# Last few logs per task
log_sections = []
if os.path.isdir(runs_dir):
    for task_dir in sorted(os.listdir(runs_dir)):
        td = os.path.join(runs_dir, task_dir)
        if not os.path.isdir(td):
            continue
        logs = sorted(glob.glob(os.path.join(td, "*.log")), reverse=True)
        if not logs:
            continue
        last_log = logs[0]
        log_name = os.path.basename(last_log)
        try:
            with open(last_log) as f:
                lines = f.readlines()
            tail = "".join(lines[-20:]).strip()
        except Exception:
            tail = "(erro ao ler log)"
        log_sections.append(f"### {task_dir} — `{log_name}`\n```\n{tail}\n```")

updated = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

lines = [
    "# Cron Status",
    f"> Atualizado: {updated}",
    "",
    "## Saúde",
    "| Último Tick | Runs (total) | Taxa Sucesso |",
    "|-------------|--------------|--------------|",
    f"| {heartbeat_age} | {total_runs} | {success_rate}% |",
    "",
    "## Tasks Recorrentes",
    "| Task | Último Run | Status | Duração | Média | Histórico |",
    "|------|------------|--------|---------|-------|-----------|",
]
lines.extend(task_rows)

if log_sections:
    lines += ["", "## Últimos Logs (20 linhas)"]
    for s in log_sections:
        lines += ["", s]

with open(status_file, "w") as f:
    f.write("\n".join(lines) + "\n")

print(f"[puppy-status] STATUS.md atualizado ({len(tasks)} tasks)")
PYEOF
