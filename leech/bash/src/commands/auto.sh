# Executa agents e tasks vencidos — timer systemd (10min)
zion_load_config

ZION_DIR="${ZION_ROOT:-${ZION_NIXOS_DIR:-$HOME/nixos}/self}"
OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
RUNNER="$ZION_DIR/scripts/task-runner.sh"
SCHEDULE="${SCHEDULE_DIR:-$OBSIDIAN/agents/_schedule}"
TASKS="$OBSIDIAN/tasks"

# Fallbacks runner
if [ ! -f "$RUNNER" ]; then
  for try in /workspace/mnt/self /workspace/nixos/self; do
    [ -f "$try/scripts/task-runner.sh" ] && RUNNER="$try/scripts/task-runner.sh" && break
  done
fi

# Fallbacks _schedule
if [ ! -d "$SCHEDULE" ]; then
  for try in /workspace/obsidian/agents/_schedule "$HOME/obsidian/agents/_schedule"; do
    [ -d "$try" ] && SCHEDULE="$try" && break
  done
fi

# Fallbacks tasks
if [ ! -d "$TASKS" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && TASKS="$try" && break
  done
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
RUNNING_DIR="$(dirname "$SCHEDULE")/_running"

# ── rescue orphans from _running/ (before scan) ──────────────
ORPHAN_COUNT=0
if [ -d "$RUNNING_DIR" ] && [ -z "$DRY_RUN" ]; then
  mkdir -p "$SCHEDULE"
  for card_path in "$RUNNING_DIR"/*.md; do
    [ -f "$card_path" ] || continue
    filename=$(basename "$card_path")
    base="${filename%.md}"
    [ -d "/tmp/zion-locks/${base}.lock" ] && continue
    ts=$(card_epoch "$filename")
    [ "$ts" -eq 0 ] && continue
    elapsed=$(( (NOW - ts) / 60 ))
    [ "$elapsed" -lt 30 ] && continue
    AGENT=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2}' "$card_path")
    echo "[auto] orphan: $filename  agent=$AGENT  stuck=${elapsed}min → _schedule"
    mv "$card_path" "$SCHEDULE/$filename" 2>/dev/null || true
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  done
  [ "$ORPHAN_COUNT" -gt 0 ] && echo "[auto] rescued $ORPHAN_COUNT orphan(s)"
elif [ -d "$RUNNING_DIR" ] && [ -n "$DRY_RUN" ]; then
  for card_path in "$RUNNING_DIR"/*.md; do
    [ -f "$card_path" ] || continue
    filename=$(basename "$card_path")
    base="${filename%.md}"
    [ -d "/tmp/zion-locks/${base}.lock" ] && continue
    ts=$(card_epoch "$filename")
    [ "$ts" -eq 0 ] && continue
    elapsed=$(( (NOW - ts) / 60 ))
    [ "$elapsed" -lt 30 ] && continue
    AGENT=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2}' "$card_path")
    echo "[auto] orphan (dry-run): $filename  agent=$AGENT  stuck=${elapsed}min"
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  done
fi

# ── scan agents/_schedule/ ─────────────────────────────────────
AGENT_DUE=()

if [ -d "$SCHEDULE" ]; then
  for card_path in "$SCHEDULE"/*.md; do
    [ -f "$card_path" ] || continue
    filename=$(basename "$card_path")
    ts=$(card_epoch "$filename")
    [ "$ts" -eq 0 ] && continue
    [ "$ts" -gt "$AGENT_THRESHOLD" ] && continue
    is_agent_card "$card_path" || continue
    AGENT=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2}' "$card_path")
    DELTA=$(( (NOW - ts) / 60 ))
    echo "[auto] agent due: $filename  agent=$AGENT  atraso=${DELTA}min"
    AGENT_DUE+=("$filename")
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
    if [ ! -d "/tmp/zion-locks/${base}.lock" ]; then
      TASK_DUE+=("$filename")
      TASK_STEPS+=("$(card_steps "$TASKS/DOING/$filename")")
    fi
  done
fi

# ── report ─────────────────────────────────────────────────────
echo ""
echo "[auto] ${#AGENT_DUE[@]} agent(s) + ${#TASK_DUE[@]} task(s) due"

if [ ${#AGENT_DUE[@]} -eq 0 ] && [ ${#TASK_DUE[@]} -eq 0 ]; then
  echo "[auto] nada para executar."
  exit 0
fi

if [ -n "$DRY_RUN" ]; then
  echo "[auto] --dry-run: nao executando"
  exit 0
fi

# ── execute agents ─────────────────────────────────────────────
for filename in "${AGENT_DUE[@]}"; do
  echo ""
  echo "[auto] ▸ agent: $filename"
  export TASK_CONTRACTORS_DIR="$(dirname "$SCHEDULE")"
  export SCHEDULE_DIR="$SCHEDULE"
  bash "$RUNNER" "$filename" || echo "[auto] $filename falhou (continuando)"
done

# ── execute tasks ──────────────────────────────────────────────
export TASK_DIR="$TASKS"
export TASK_AGENTS_DIR="$(dirname "$TASKS")/vault/agents"

for i in "${!TASK_DUE[@]}"; do
  filename="${TASK_DUE[$i]}"
  steps="${STEPS_OVERRIDE:-${TASK_STEPS[$i]}}"
  echo ""
  echo "[auto] ▸ task: $filename  steps=$steps"

  base="${filename%.md}"
  rm -rf "/tmp/zion-locks/${base}.lock" 2>/dev/null || true

  TASK_MAX_TURNS="$steps" bash "$RUNNER" "$filename" || echo "[auto] $filename falhou (continuando)"
done

echo ""
echo "[auto] concluido"
