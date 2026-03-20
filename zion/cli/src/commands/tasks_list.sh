# List task cards or cron logs
zion_load_config
local show_all="${args[--all]:-}"
local show_log="${args[--log]:-}"
local log_lines="${args[--lines]:-20}"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local tasks="$obsidian/tasks"

# Fallback paths
if [ ! -d "$tasks" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

if [ ! -d "$tasks" ]; then
  echo "Tasks dir not found"
  exit 1
fi

# --log: show cron execution logs
if [ -n "$show_log" ]; then
  local logdir="$(dirname "$tasks")/vault/.ephemeral/cron-logs"
  if [ ! -d "$logdir" ]; then
    echo "No cron logs found at $logdir"
    exit 0
  fi
  echo "=== Cron Logs (last runs) ==="
  for agent_dir in "$logdir"/*/; do
    [ -d "$agent_dir" ] || continue
    local agent=$(basename "$agent_dir")
    local latest=$(ls -t "$agent_dir"*.log 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
      echo ""
      echo "--- $agent ($(basename "$latest")) ---"
      tail -n "$log_lines" "$latest"
    fi
  done
  exit 0
fi

# Cards mode
echo "=== TODO ==="
ls "$tasks/TODO/"*.md 2>/dev/null | xargs -I{} basename {} | sort || echo "  (empty)"
echo ""
echo "=== DOING ==="
ls "$tasks/DOING/"*.md 2>/dev/null | xargs -I{} basename {} | sort || echo "  (empty)"

if [ -n "$show_all" ]; then
  echo ""
  echo "=== DONE (last 20) ==="
  ls -t "$tasks/DONE/"*.md 2>/dev/null | head -20 | xargs -I{} basename {} || echo "  (empty)"
fi
