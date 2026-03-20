# Run a task card by name (local, no container)
local name="${args[name]}"
local max_turns="${args[--max-turns]:-}"
zion_load_config

local zion_dir="${ZION_ROOT:-$HOME/nixos/zion}"
local runner="$zion_dir/scripts/task-runner.sh"
local tasks="${OBSIDIAN_PATH:-$HOME/.ovault/Work}/tasks"
[ ! -d "$tasks" ] && tasks="/workspace/obsidian/tasks"

# Clear stale locks
rm -rf "/tmp/zion-locks/"*"${name}"* 2>/dev/null || true

# Find card
local card=""
for f in "$tasks/TODO/"*_"${name}".md "$tasks/DOING/"*_"${name}".md; do
  [ -f "$f" ] && card=$(basename "$f") && break
done

if [ -z "$card" ]; then
  echo "Card '${name}' not found in TODO/ or DOING/"
  echo "Available:"
  ls "$tasks/TODO/" 2>/dev/null | sed 's/^/  TODO: /'
  ls "$tasks/DOING/" 2>/dev/null | sed 's/^/  DOING: /'
  exit 1
fi

export TASK_DIR="$tasks"
export TASK_MEMORY_DIR="$(dirname "$tasks")/agents/memory"
[ -n "$max_turns" ] && export TASK_MAX_TURNS="$max_turns"

exec "$runner" "$card"
