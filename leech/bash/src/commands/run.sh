# Roda um agente ou task imediatamente
local name="${args[name]}"
local steps="${args[--steps]:-}"
leech_load_config

local leech_dir="${LEECH_ROOT:-$HOME/nixos/self}"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local runner="$leech_dir/scripts/task-runner.sh"
local agents="$obsidian/agents"
local schedule="$agents/_schedule"
local tasks="$obsidian/tasks"
local agent_file="$leech_dir/agents/${name}/agent.md"

# Fallback runner paths
if [ ! -f "$runner" ]; then
  for try in \
    "/workspace/mnt/self/scripts/task-runner.sh" \
    "/workspace/nixos/self/scripts/task-runner.sh"; do
    [ -f "$try" ] && runner="$try" && break
  done
fi

if [ ! -f "$runner" ]; then
  echo "[run] task-runner nao encontrado"
  exit 1
fi

# Fallback agent.md paths
if [ ! -f "$agent_file" ]; then
  for try in \
    "/workspace/mnt/self/agents/${name}/agent.md" \
    "/workspace/nixos/self/agents/${name}/agent.md"; do
    [ -f "$try" ] && agent_file="$try" && break
  done
fi

# Fallback agents dir
if [ ! -d "$agents" ]; then
  for try in /workspace/obsidian/agents "$HOME/obsidian/agents"; do
    [ -d "$try" ] && agents="$try" && schedule="$try/_schedule" && break
  done
fi

# Fallback tasks dir
if [ ! -d "$tasks" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

# ── Detect: agent or task? ─────────────────────────────────────
if [ -f "$agent_file" ]; then
  # ── AGENT PATH ───────────────────────────────────────────────
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

  case "$MODEL" in
    haiku)  TIMEOUT=900  ;;
    opus)   TIMEOUT=3600 ;;
    *)      TIMEOUT=1800 ;;
  esac

  if [ -z "$steps" ]; then
    case "$MODEL" in
      haiku)  steps=20 ;;
      opus)   steps=60 ;;
      *)      steps=40 ;;
    esac
  fi

  WHEN=$(date -u +%Y%m%d_%H_%M)
  CARD="${WHEN}_${name}.md"

  mkdir -p "$schedule"
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
  } > "$schedule/$CARD"

  echo "[run] agent '${name}' -> card $CARD"
  echo "[run] model=$MODEL  timeout=${TIMEOUT}s  steps=$steps"
  echo ""

  rm -rf "/tmp/leech-locks/${WHEN}_${name}.lock" 2>/dev/null || true

  export TASK_CONTRACTORS_DIR="$agents"
  export SCHEDULE_DIR="$schedule"
  export TASK_MAX_TURNS="$steps"

  exec "$runner" "$CARD"

else
  # ── TASK PATH ────────────────────────────────────────────────
  if [ ! -d "$tasks" ]; then
    echo "[run] '$name' nao e agente nem task dir encontrado"
    exit 1
  fi

  CARD=""
  CARD_DIR=""
  for dir in "$tasks/TODO" "$tasks/DOING"; do
    for f in "$dir"/*"${name}"*.md; do
      [ -f "$f" ] && CARD=$(basename "$f") && CARD_DIR="$dir" && break 2
    done
  done

  if [ -z "$CARD" ]; then
    echo "[run] '$name' nao encontrado como agente nem task"
    echo ""
    echo "Agentes disponiveis:"
    for try in "$leech_dir/agents" "/workspace/mnt/self/agents"; do
      [ -d "$try" ] && ls "$try" | sed 's/^/  /' && break
    done
    echo ""
    echo "Tasks disponiveis:"
    ls "$tasks/TODO/"*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  TODO: /'
    ls "$tasks/DOING/"*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  DOING: /'
    exit 1
  fi

  echo "[run] task: $CARD"

  local base="${CARD%.md}"
  rm -rf "/tmp/leech-locks/${base}.lock" 2>/dev/null || true

  export TASK_DIR="$tasks"
  export TASK_AGENTS_DIR="$(dirname "$tasks")/vault/agents"
  [ -n "$steps" ] && export TASK_MAX_TURNS="$steps"

  exec "$runner" "$CARD"
fi
