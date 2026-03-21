# Executa todos os contractor cards vencidos em contractors/_schedule/
# Um "contractor card" tem campo `agent:` ou `contractor:` no frontmatter
zion_load_config

ZION_DIR="${ZION_ROOT:-${ZION_NIXOS_DIR:-$HOME/nixos}/zion}"
OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
SCHEDULE="${SCHEDULE_DIR:-$OBSIDIAN/agents/_schedule}"
RUNNER="$ZION_DIR/scripts/task-runner.sh"

# Fallbacks runner
if [ ! -f "$RUNNER" ]; then
  for try in /workspace/mnt/zion /workspace/nixos/zion; do
    [ -f "$try/scripts/task-runner.sh" ] && RUNNER="$try/scripts/task-runner.sh" && break
  done
fi

# Fallbacks _schedule
if [ ! -d "$SCHEDULE" ]; then
  for try in "$OBSIDIAN/agents/_schedule" /workspace/obsidian/agents/_schedule "$HOME/obsidian/agents/_schedule"; do
    [ -d "$try" ] && SCHEDULE="$try" && break
  done
fi

DRY_RUN="${args[--dry-run]:-}"

if [ ! -d "$SCHEDULE" ]; then
  echo "[work] agents/_schedule nao encontrado: $SCHEDULE"
  exit 1
fi
if [ ! -f "$RUNNER" ]; then
  echo "[work] task-runner nao encontrado: $RUNNER"
  exit 1
fi

# Parse data do nome do card: YYYYMMDD_HH_MM_name.md → epoch
card_epoch() {
  local name="$1"
  if [[ "$name" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    local y="${BASH_REMATCH[1]}" mo="${BASH_REMATCH[2]}" d="${BASH_REMATCH[3]}"
    local h="${BASH_REMATCH[4]}" mi="${BASH_REMATCH[5]}"
    date -d "${y}-${mo}-${d} ${h}:${mi}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

# Checar se card tem agent: ou contractor: no frontmatter
is_contractor_card() {
  local file="$1"
  local in_fm=0
  while IFS= read -r line; do
    [ "$line" = "---" ] && { [ "$in_fm" = "1" ] && break; in_fm=1; continue; }
    [ "$in_fm" = "1" ] || continue
    case "$line" in agent:* | contractor:*) return 0 ;; esac
  done < "$file"
  return 1
}

NOW=$(date +%s)
THRESHOLD=$((NOW + 300))  # 5min de tolerância
DUE=()

for card_path in "$SCHEDULE"/*.md; do
  [ -f "$card_path" ] || continue
  filename=$(basename "$card_path")

  ts=$(card_epoch "$filename")
  [ "$ts" -eq 0 ] && continue
  [ "$ts" -gt "$THRESHOLD" ] && continue

  is_contractor_card "$card_path" || continue

  AGENT=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2}' "$card_path")
  DELTA=$(( (NOW - ts) / 60 ))
  echo "[work] due: $filename  agent=$AGENT  atraso=${DELTA}min"
  DUE+=("$filename")
done

if [ ${#DUE[@]} -eq 0 ]; then
  echo "[work] nenhum contractor card vencido."
  exit 0
fi

echo "[work] ${#DUE[@]} card(s) para executar"

if [ -n "$DRY_RUN" ]; then
  echo "[work] --dry-run: nao executando"
  exit 0
fi

# Executar em série (evitar estouro de quota)
for filename in "${DUE[@]}"; do
  echo "[work] → $filename"
  export TASK_CONTRACTORS_DIR="$(dirname "$SCHEDULE")"
  export SCHEDULE_DIR="$SCHEDULE"
  bash "$RUNNER" "$filename" || echo "[work] $filename falhou (continuando)"
done

echo "[work] concluido"
