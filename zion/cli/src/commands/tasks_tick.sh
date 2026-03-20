# Run a local tick: find due cards, report, execute serially
# Parses #stepsN tag from card body as max_turns (fallback: 30)
zion_load_config
ZION_DIR="${ZION_ROOT:-${HOME}/nixos/zion}"
RUNNER="$ZION_DIR/scripts/task-runner.sh"
TASKS="${OBSIDIAN_PATH:-${HOME}/.ovault/Work}/tasks"
# Fallback: find tasks dir from common paths
if [ ! -d "$TASKS" ]; then
  for try in "$ZION_DIR/../obsidian/tasks" /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && TASKS="$try" && break
  done
fi

DRY_RUN="${args[--dry-run]:-}"
STEPS_OVERRIDE="${args[--steps]:-}"
DEFAULT_STEPS=30

now=$(date +%s)
threshold=$((now + 600))  # 10 min ahead

# ── helpers ──────────────────────────────────────────────────────
card_epoch() {
  local name="$1"
  if [[ "$name" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

card_steps() {
  local file="$1"
  # look for #stepsN or #steps N anywhere in card body
  local n
  n=$(grep -oE '#steps[[:space:]]*[0-9]+' "$file" 2>/dev/null | grep -oE '[0-9]+' | head -1)
  echo "${n:-$DEFAULT_STEPS}"
}

# ── scan TODO/ ───────────────────────────────────────────────────
due=()
due_steps=()

for card in "$TASKS/TODO"/*.md; do
  [ -f "$card" ] || continue
  filename=$(basename "$card")
  ts=$(card_epoch "$filename")
  [ "$ts" -eq 0 ] && continue
  [ "$ts" -le "$threshold" ] && due+=("$filename") && due_steps+=("$(card_steps "$card")")
done

# orphans in DOING (not locked)
for card in "$TASKS/DOING"/*.md; do
  [ -f "$card" ] || continue
  filename=$(basename "$card")
  base=$(basename "$filename" .md)
  if [ ! -d "/tmp/zion-locks/${base}.lock" ]; then
    due+=("$filename")
    due_steps+=("$(card_steps "$TASKS/DOING/$filename")")
  fi
done

# ── report ───────────────────────────────────────────────────────
total=${#due[@]}

if [ "$total" -eq 0 ]; then
  echo "Nenhum card vencido em TODO/."
  exit 0
fi

echo "Cards vencidos: $total"
echo ""
for i in "${!due[@]}"; do
  steps="${STEPS_OVERRIDE:-${due_steps[$i]}}"
  delta=$(( ( $(card_epoch "${due[$i]}") - now ) / 60 ))
  printf "  [%d/%d] %-50s  #steps=%s  (%+dmin)\n" \
    "$((i+1))" "$total" "${due[$i]}" "$steps" "$delta"
done
echo ""

[ -n "$DRY_RUN" ] && echo "(dry-run — nao executando)" && exit 0

# ── execute serially ─────────────────────────────────────────────
for i in "${!due[@]}"; do
  filename="${due[$i]}"
  steps="${STEPS_OVERRIDE:-${due_steps[$i]}}"
  echo "━━━ [$((i+1))/$total] $filename  (steps=$steps)"
  TASK_MAX_TURNS="$steps" "$RUNNER" "$filename" || true
  echo ""
done

echo "Tick concluido ($total cards)."
