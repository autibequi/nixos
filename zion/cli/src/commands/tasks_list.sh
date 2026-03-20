# List task cards — local fallback se puppy não estiver rodando
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"
local show_all="${args[--all]:-}"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"

local cmd="T=/workspace/obsidian/tasks; echo '=== TODO ==='; ls \$T/TODO/*.md 2>/dev/null | xargs -I{} basename {} | sort || echo '  (empty)'; echo; echo '=== DOING ==='; ls \$T/DOING/*.md 2>/dev/null | xargs -I{} basename {} | sort || echo '  (empty)'"
if [ -n "$show_all" ]; then
  cmd="$cmd; echo; echo '=== DONE (last 20) ==='; ls -t \$T/DONE/*.md 2>/dev/null | head -20 | xargs -I{} basename {} || echo '  (empty)'"
fi

# Tenta via container puppy
if docker compose -f "$compose_file" ps --status running 2>/dev/null | grep -q puppy; then
  docker compose -f "$compose_file" exec -T -u claude puppy bash -c "$cmd" 2>/dev/null
  exit 0
fi

# Fallback local: lê direto do filesystem
local tasks="$obsidian/tasks"
if [ ! -d "$tasks" ]; then
  # Tenta path dentro do container
  tasks="/workspace/obsidian/tasks"
fi

if [ ! -d "$tasks" ]; then
  echo "Tasks dir not found (puppy not running e path local não encontrado)"
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
