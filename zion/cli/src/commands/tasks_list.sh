# List task cards inside puppy container
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"
local show_all="${args[--all]:-}"

local cmd="T=/workspace/obsidian/tasks; echo '=== TODO ==='; ls \$T/TODO/*.md 2>/dev/null | xargs -I{} basename {} | sort || echo '  (empty)'; echo; echo '=== DOING ==='; ls \$T/DOING/*.md 2>/dev/null | xargs -I{} basename {} | sort || echo '  (empty)'"

if [ -n "$show_all" ]; then
  cmd="$cmd; echo; echo '=== DONE (last 20) ==='; ls -t \$T/DONE/*.md 2>/dev/null | head -20 | xargs -I{} basename {} || echo '  (empty)'"
fi

docker compose -f "$compose_file" exec -T puppy bash -c "$cmd" 2>/dev/null || {
  echo "Puppy container not running. Start with: zion puppy start"
  exit 1
}
