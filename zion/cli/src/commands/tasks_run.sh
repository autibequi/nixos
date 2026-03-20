# Run a task card by name locally
local name="${args[name]}"
local max_turns="${args[--max-turns]:-}"
zion_load_config
local zion_dir="${ZION_ROOT:-$HOME/nixos/zion}"
local runner="$zion_dir/scripts/task-runner.sh"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local tasks="$obsidian/tasks"

# Fallback paths
if [ ! -d "$tasks" ]; then
  for try in "$zion_dir/../obsidian/tasks" /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

if [ ! -d "$tasks" ]; then
  echo "Tasks dir not found"
  exit 1
fi

# Find card by name
CARD=""
for f in "$tasks/TODO/"*_${name}.md "$tasks/DOING/"*_${name}.md; do
  [ -f "$f" ] && CARD=$(basename "$f") && break
done

if [ -z "$CARD" ]; then
  echo "Card '${name}' not found in TODO/ or DOING/"
  echo "Available:"
  ls "$tasks/TODO/" 2>/dev/null | sed 's/^/  TODO: /'
  ls "$tasks/DOING/" 2>/dev/null | sed 's/^/  DOING: /'
  exit 1
fi

# Clear stale locks
rm -rf "/tmp/zion-locks/"*"${name}"* 2>/dev/null || true

# Export paths for task-runner.sh
export TASK_DIR="$tasks"
export TASK_AGENTS_DIR="$(dirname "$tasks")/vault/agents"
[ -n "$max_turns" ] && export TASK_MAX_TURNS="$max_turns"

exec "$runner" "$CARD"
