# List task cards (local)
zion_load_config
local show_all="${args[--all]:-}"
local tasks="${OBSIDIAN_PATH:-$HOME/.ovault/Work}/tasks"
[ ! -d "$tasks" ] && tasks="/workspace/obsidian/tasks"

if [ ! -d "$tasks" ]; then
  echo "Tasks dir not found: $tasks"
  exit 1
fi

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
