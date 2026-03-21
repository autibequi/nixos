# Run a task card by name from tasks/TODO or tasks/DOING
local name="${args[name]}"
local steps_override="${args[--steps]:-}"
zion_load_config

local zion_dir="${ZION_ROOT:-$HOME/nixos/zion}"
local runner="$zion_dir/scripts/task-runner.sh"
local tasks="${OBSIDIAN_PATH:-$HOME/.ovault/Work}/tasks"

# Fallback paths
if [ ! -d "$tasks" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

# Fallback runner
if [ ! -f "$runner" ]; then
  for try in /workspace/mnt/zion/scripts/task-runner.sh /workspace/nixos/zion/scripts/task-runner.sh; do
    [ -f "$try" ] && runner="$try" && break
  done
fi

if [ ! -d "$tasks" ]; then
  echo "[tasks] dir not found"
  exit 1
fi

if [ ! -f "$runner" ]; then
  echo "[tasks] runner not found"
  exit 1
fi

# Find card by name (partial match on suffix)
CARD=""
CARD_DIR=""
for dir in "$tasks/TODO" "$tasks/DOING"; do
  for f in "$dir"/*"${name}"*.md; do
    [ -f "$f" ] && CARD=$(basename "$f") && CARD_DIR="$dir" && break 2
  done
done

if [ -z "$CARD" ]; then
  echo "Task '$name' not found in TODO/ or DOING/"
  echo ""
  echo "Available tasks:"
  ls "$tasks/TODO/"*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  TODO: /'
  ls "$tasks/DOING/"*.md 2>/dev/null | xargs -I{} basename {} .md | sed 's/^/  DOING: /'
  exit 1
fi

echo "[tasks] Running: $CARD"

# Clear stale locks
local base="${CARD%.md}"
rm -rf "/tmp/zion-locks/${base}.lock" 2>/dev/null || true

# Export paths for task-runner.sh
export TASK_DIR="$tasks"
export TASK_AGENTS_DIR="$(dirname "$tasks")/vault/agents"
[ -n "$steps_override" ] && export TASK_MAX_TURNS="$steps_override"

exec "$runner" "$CARD"
