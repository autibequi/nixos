# Show task execution log (local)
local lines="${args[--lines]:-20}"
zion_load_config
local tasks="${OBSIDIAN_PATH:-$HOME/.ovault/Work}/tasks"
[ ! -d "$tasks" ] && tasks="/workspace/obsidian/tasks"
local log="$tasks/log.md"

if [ ! -f "$log" ]; then
  echo "No task log found at $log"
  exit 0
fi
echo "=== Task Log (last $lines) ==="
tail -n "$lines" "$log"
