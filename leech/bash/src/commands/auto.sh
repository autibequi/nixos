# Executa agents e tasks vencidos — timer systemd (10min)
leech_load_config

LEECH_DIR="${LEECH_ROOT:-${LEECH_NIXOS_DIR:-$HOME/nixos}/leech/self}"
OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
RUNNER="$LEECH_DIR/scripts/task-runner.sh"
SCHEDULE="${SCHEDULE_DIR:-$OBSIDIAN/agents/_waiting}"
WORKING="${WORKING_DIR:-$OBSIDIAN/agents/_working}"
TASKS="$OBSIDIAN/tasks"

# Fallbacks runner
if [ ! -f "$RUNNER" ]; then
  _resolve_runner() {
    local t; for t in /workspace/mnt/leech/self /workspace/self /workspace/nixos/self; do
      [ -f "$t/scripts/task-runner.sh" ] && echo "$t/scripts/task-runner.sh" && return
    done
  }
  RUNNER="$(_resolve_runner)"
fi

# Fallbacks schedule
if [ ! -d "$SCHEDULE" ]; then
  _resolve_schedule() {
    local t; for t in /workspace/obsidian/agents/_waiting "$HOME/.ovault/Work/agents/_waiting"; do
      [ -d "$t" ] && echo "$t" && return
    done
  }
  SCHEDULE="$(_resolve_schedule)"
fi

# Fallbacks working
if [ ! -d "$WORKING" ]; then
  _resolve_working() {
    local t; for t in /workspace/obsidian/agents/_working "$HOME/.ovault/Work/agents/_working"; do
      [ -d "$t" ] && echo "$t" && return
    done
  }
  WORKING="$(_resolve_working)"
fi

# Fallbacks tasks
if [ ! -d "$TASKS" ]; then
  _resolve_tasks() {
    local t; for t in /workspace/obsidian/tasks "$HOME/.ovault/Work/tasks"; do
      [ -d "$t" ] && echo "$t" && return
    done
  }
  TASKS="$(_resolve_tasks)"
fi

DRY_RUN="${args[--dry-run]:-}"
STEPS_OVERRIDE="${args[--steps]:-}"

if [ ! -f "$RUNNER" ]; then
  echo "[auto] task-runner nao encontrado: $RUNNER"
  exit 1
fi

# ── helpers ──────────────────────────────────────────────────────
card_epoch() {
  local name="$1"
  if [[ "$name" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    local y="${BASH_REMATCH[1]}" mo="${BASH_REMATCH[2]}" d="${BASH_REMATCH[3]}"
    local h="${BASH_REMATCH[4]}" mi="${BASH_REMATCH[5]}"
    TZ=UTC date -d "${y}-${mo}-${d} ${h}:${mi}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

is_agent_card() {
  local file="$1"
  local in_fm=0
  while IFS= read -r line; do
    [ "$line" = "---" ] && { [ "$in_fm" = "1" ] && break; in_fm=1; continue; }
    [ "$in_fm" = "1" ] || continue
    case "$line" in agent:* | contractor:*) return 0 ;; esac
  done < "$file"
  return 1
}

card_steps() {
  local file="$1"
  local n
  n=$(grep -oE '#steps[[:space:]]*[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+' | head -1)
  echo "${n:-30}"
}

NOW=$(date +%s)
AGENT_THRESHOLD=$((NOW + 300))   # 5min tolerancia
TASK_THRESHOLD=$((NOW + 600))    # 10min tolerancia
RUNNING_DIR="$WORKING"

# ── rescue orphans from _working/ (before scan) ──────────────
ORPHAN_COUNT=0
if [ -d "$RUNNING_DIR" ] && [ -z "$DRY_RUN" ]; then
  mkdir -p "$SCHEDULE"
  for card_path in "$RUNNING_DIR"/*.md; do
    [ -f "$card_path" ] || continue
    filename=$(basename "$card_path")
    base="${filename%.md}"
    [ -d "/tmp/leech-locks/${base}.lock" ] && continue
    ts=$(card_epoch "$filename")
    [ "$ts" -eq 0 ] && continue
    elapsed=$(( (NOW - ts) / 60 ))
    [ "$elapsed" -lt 30 ] && continue
    AGENT=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2}' "$card_path")
    echo "[auto] orphan: $filename  agent=$AGENT  stuck=${elapsed}min → _working"
    mv "$card_path" "$SCHEDULE/$filename" 2>/dev/null || true
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  done
  [ "$ORPHAN_COUNT" -gt 0 ] && echo "[auto] rescued $ORPHAN_COUNT orphan(s)"
elif [ -d "$RUNNING_DIR" ] && [ -n "$DRY_RUN" ]; then
  for card_path in "$RUNNING_DIR"/*.md; do
    [ -f "$card_path" ] || continue
    filename=$(basename "$card_path")
    base="${filename%.md}"
    [ -d "/tmp/leech-locks/${base}.lock" ] && continue
    ts=$(card_epoch "$filename")
    [ "$ts" -eq 0 ] && continue
    elapsed=$(( (NOW - ts) / 60 ))
    [ "$elapsed" -lt 30 ] && continue
    AGENT=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2}' "$card_path")
    echo "[auto] orphan (dry-run): $filename  agent=$AGENT  stuck=${elapsed}min"
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  done
fi

# ── tick agent resolve path ────────────────────────────────────
TICK_AGENT="$LEECH_DIR/agents/tick/agent.md"
if [ ! -f "$TICK_AGENT" ]; then
  for _try in /workspace/self/agents/tick/agent.md \
              /workspace/mnt/leech/self/agents/tick/agent.md; do
    [ -f "$_try" ] && TICK_AGENT="$_try" && break
  done
fi

# ── scan tasks/TODO/ + orphans DOING/ ──────────────────────────
TASK_DUE=()
TASK_STEPS=()

if [ -d "$TASKS" ]; then
  for card in "$TASKS/TODO"/*.md; do
    [ -f "$card" ] || continue
    filename=$(basename "$card")
    ts=$(card_epoch "$filename")
    [ "$ts" -eq 0 ] && continue
    [ "$ts" -le "$TASK_THRESHOLD" ] && TASK_DUE+=("$filename") && TASK_STEPS+=("$(card_steps "$card")")
  done

  # orphans in DOING (not locked)
  for card in "$TASKS/DOING"/*.md; do
    [ -f "$card" ] || continue
    filename=$(basename "$card")
    base="${filename%.md}"
    if [ ! -d "/tmp/leech-locks/${base}.lock" ]; then
      TASK_DUE+=("$filename")
      TASK_STEPS+=("$(card_steps "$TASKS/DOING/$filename")")
    fi
  done
fi

# ── report ─────────────────────────────────────────────────────
echo ""
echo "[auto] tick + ${#TASK_DUE[@]} task(s) due"

if [ -n "$DRY_RUN" ]; then
  echo "[auto] --dry-run: tick seria chamado (${TICK_AGENT})"
  echo "[auto] --dry-run: nao executando"
  exit 0
fi

# ── tick agent (despacha agentes) ──────────────────────────────
_run_claude() {
  if [ "$(id -u)" = "0" ]; then
    setpriv --reuid=1000 --regid=1000 --keep-groups \
      env USER=claude LOGNAME=claude HOME=/home/claude \
      claude "$@"
  else
    claude "$@"
  fi
}

if [ -f "$TICK_AGENT" ]; then
  echo ""
  echo "[auto] ▸ tick"
  TICK_PROMPT=$(awk 'BEGIN{fm=0} /^---/{fm++; next} fm>=2{print}' "$TICK_AGENT")
  HEADLESS=1 timeout 300 _run_claude \
    --permission-mode bypassPermissions \
    --model haiku \
    --max-turns 20 \
    -p "$TICK_PROMPT" \
    --add-dir "$HOME" 2>&1 || echo "[auto] tick falhou"
else
  echo "[auto] tick agent nao encontrado: $TICK_AGENT"
fi

# ── execute tasks ──────────────────────────────────────────────
export TASK_DIR="$TASKS"
export TASK_AGENTS_DIR="$(dirname "$TASKS")/vault/agents"

for i in "${!TASK_DUE[@]}"; do
  filename="${TASK_DUE[$i]}"
  steps="${STEPS_OVERRIDE:-${TASK_STEPS[$i]}}"
  echo ""
  echo "[auto] ▸ task: $filename  steps=$steps"

  base="${filename%.md}"
  rm -rf "/tmp/leech-locks/${base}.lock" 2>/dev/null || true

  TASK_MAX_TURNS="$steps" bash "$RUNNER" "$filename" || echo "[auto] $filename falhou (continuando)"
done

echo ""
echo "[auto] concluido"
