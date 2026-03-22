# Lanca o agente Tasker para processar tasks atrasadas agora
# Equivalente a: zion run tasker
zion_load_config

steps="${args[--steps]:-}"

zion_dir="${ZION_ROOT:-$HOME/nixos/self}"
obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
runner="$zion_dir/scripts/task-runner.sh"
agents="$obsidian/agents"
schedule="$agents/_schedule"
agent_file="$zion_dir/agents/tasker/agent.md"

# Fallback runner
if [ ! -f "$runner" ]; then
  for try in "/workspace/mnt/self/scripts/task-runner.sh" "/workspace/self/scripts/task-runner.sh"; do
    [ -f "$try" ] && runner="$try" && break
  done
fi

# Fallback agent.md
if [ ! -f "$agent_file" ]; then
  for try in "/workspace/mnt/self/agents/tasker/agent.md" "/workspace/self/agents/tasker/agent.md"; do
    [ -f "$try" ] && agent_file="$try" && break
  done
fi

# Fallback agents dir
if [ ! -d "$agents" ]; then
  for try in /workspace/obsidian/agents "$HOME/obsidian/agents"; do
    [ -d "$try" ] && agents="$try" && schedule="$try/_schedule" && break
  done
fi

if [ ! -f "$runner" ]; then
  echo "[tasker] task-runner nao encontrado"
  exit 1
fi

if [ ! -f "$agent_file" ]; then
  echo "[tasker] agent.md nao encontrado: $agent_file"
  exit 1
fi

# Ler model e max_turns do agent.md
_fm_val() {
  local key="$1"
  awk '/^---/{fm++} fm==1 && /^'"$key"':/{gsub(/^[^:]*:[[:space:]]*/,""); print; exit}' "$agent_file" 2>/dev/null
}

MODEL=$(_fm_val "model"); MODEL="${MODEL:-sonnet}"
MAX_TURNS=$(_fm_val "max_turns"); MAX_TURNS="${MAX_TURNS:-15}"
MCP=$(_fm_val "mcp"); MCP="${MCP:-false}"
TIMEOUT=1800
case "$MODEL" in haiku) TIMEOUT=900 ;; opus) TIMEOUT=3600 ;; esac

[ -n "$steps" ] && MAX_TURNS="$steps"

# Corpo do agente (abaixo do frontmatter)
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

WHEN=$(date -u +%Y%m%d_%H_%M)
CARD="${WHEN}_tasker.md"

mkdir -p "$schedule"
{
  echo "---"
  echo "model: $MODEL"
  echo "timeout: $TIMEOUT"
  echo "mcp: $MCP"
  echo "agent: tasker"
  echo "---"
  _agent_body
  echo ""
  echo "#steps${MAX_TURNS}"
} > "$schedule/$CARD"

echo "[tasker] agent=tasker  model=$MODEL  turns=$MAX_TURNS  timeout=${TIMEOUT}s"
echo "[tasker] card: $CARD"
echo ""

rm -rf "/tmp/zion-locks/${WHEN}_tasker.lock" 2>/dev/null || true

export TASK_CONTRACTORS_DIR="$agents"
export SCHEDULE_DIR="$schedule"
export TASK_MAX_TURNS="$MAX_TURNS"

exec "$runner" "$CARD"
