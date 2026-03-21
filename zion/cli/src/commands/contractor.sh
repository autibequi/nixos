# Roda um contractor imediatamente — mesmo fluxo de execucao do scheduler
local name="${args[name]}"
local steps="${args[--steps]:-}"
zion_load_config

local zion_dir="${ZION_ROOT:-$HOME/nixos/zion}"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local tasks="$obsidian/tasks"
local runner="$zion_dir/scripts/task-runner.sh"
local agent_file="$zion_dir/agents/${name}/agent.md"

# Fallback runner paths
if [ ! -f "$runner" ]; then
  for try in \
    "/workspace/mnt/zion/scripts/task-runner.sh" \
    "/workspace/nixos/zion/scripts/task-runner.sh"; do
    [ -f "$try" ] && runner="$try" && break
  done
fi

# Fallback agent.md paths
if [ ! -f "$agent_file" ]; then
  for try in \
    "/workspace/mnt/zion/agents/${name}/agent.md" \
    "/workspace/nixos/zion/agents/${name}/agent.md"; do
    [ -f "$try" ] && agent_file="$try" && break
  done
fi

if [ ! -f "$agent_file" ]; then
  echo "Contractor '${name}' nao encontrado."
  for try in \
    "$zion_dir/agents" \
    "/workspace/mnt/zion/agents" \
    "/workspace/nixos/zion/agents"; do
    if [ -d "$try" ]; then
      echo "Contractors disponiveis:"
      ls "$try" | sed 's/^/  /'
      break
    fi
  done
  exit 1
fi

# Fallback tasks dir
if [ ! -d "$tasks" ]; then
  for try in \
    "$zion_dir/../obsidian/tasks" \
    /workspace/obsidian/tasks \
    "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

if [ ! -d "$tasks" ]; then
  echo "Tasks dir nao encontrado."
  exit 1
fi

# ── Parse frontmatter do agent.md ───────────────────────────────
_parse_agent_fm() {
  local key="$1"
  local in_fm=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      [ "$in_fm" = "1" ] && break
      in_fm=1; continue
    fi
    [ "$in_fm" = "1" ] || continue
    case "$line" in
      "${key}:"*) echo "${line#*: }" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; return ;;
    esac
  done < "$agent_file"
}

_agent_body() {
  local in_fm=0 past_fm=0
  while IFS= read -r line; do
    [ "$past_fm" = "1" ] && { echo "$line"; continue; }
    if [ "$line" = "---" ]; then
      [ "$in_fm" = "1" ] && past_fm=1 && continue
      in_fm=1; continue
    fi
  done < "$agent_file"
}

MODEL=$(_parse_agent_fm "model")
MODEL="${MODEL:-sonnet}"

# Timeout por modelo
case "$MODEL" in
  haiku)  TIMEOUT=900  ;;
  opus)   TIMEOUT=3600 ;;
  *)      TIMEOUT=1800 ;;
esac

# Steps por modelo (se nao passado via --steps)
if [ -z "$steps" ]; then
  case "$MODEL" in
    haiku)  steps=20 ;;
    opus)   steps=60 ;;
    *)      steps=40 ;;
  esac
fi

# ── Card temporario em TODO/ ─────────────────────────────────────
WHEN=$(date +%Y%m%d_%H_%M)
CARD="${WHEN}_${name}.md"

mkdir -p "$tasks/TODO"
{
  echo "---"
  echo "model: $MODEL"
  echo "timeout: $TIMEOUT"
  echo "mcp: false"
  echo "agent: $name"
  echo "---"
  _agent_body
  echo ""
  echo "#steps${steps}"
} > "$tasks/TODO/$CARD"

echo "[contractor] '${name}' -> card $CARD"
echo "[contractor] model=$MODEL  timeout=${TIMEOUT}s  steps=$steps"
echo "[contractor] agent.md: $agent_file"
echo ""

rm -rf "/tmp/zion-locks/${WHEN}_${name}.lock" 2>/dev/null || true

export TASK_DIR="$tasks"
export TASK_AGENTS_DIR="$(dirname "$tasks")/vault/agents"
export TASK_MAX_TURNS="$steps"

exec "$runner" "$CARD"
