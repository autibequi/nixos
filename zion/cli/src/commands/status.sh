# Status agregado: sessões, docker services e puppy workers
zion_load_config
local compose_zion="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.zion.yml"
local compose_puppy="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"
local obsidian="${OBSIDIAN_PATH:-/workspace/obsidian}"
[ ! -d "$obsidian" ] && obsidian="/workspace/obsidian"

echo "=== Zion Status ==="
echo ""

# Docker containers
echo "--- Containers ---"
if docker compose -f "$compose_zion" ps 2>/dev/null | grep -v "^NAME" | grep -v "^$"; then
  true
else
  echo "  (sem acesso ao Docker ou nenhum container)"
fi

echo ""
echo "--- Puppy ---"
if docker compose -f "$compose_puppy" ps --status running 2>/dev/null | grep -q puppy; then
  echo "  puppy: RUNNING"
  docker compose -f "$compose_puppy" exec -T -u claude puppy \
    bash -c "echo \"  tasks TODO: \$(ls /workspace/obsidian/tasks/TODO/*.md 2>/dev/null | wc -l)\"" 2>/dev/null || true
else
  echo "  puppy: STOPPED"
fi

echo ""
echo "--- Tasks (local) ---"
local tasks="$obsidian/tasks"
if [ -d "$tasks" ]; then
  echo "  TODO:  $(ls "$tasks/TODO/"*.md 2>/dev/null | wc -l | tr -d ' ')"
  echo "  DOING: $(ls "$tasks/DOING/"*.md 2>/dev/null | wc -l | tr -d ' ')"
  echo "  DONE:  $(ls "$tasks/DONE/"*.md 2>/dev/null | wc -l | tr -d ' ')"
  echo ""
  echo "  Última execução:"
  tail -3 "$tasks/log.md" 2>/dev/null | sed 's/^/    /' || echo "    (sem log)"
else
  echo "  (tasks dir não encontrado)"
fi

echo ""
echo "--- Cota ---"
local usage_script="${ZION_ROOT:-$HOME/nixos/zion}/scripts/claude-ai-usage.sh"
[ -x "$usage_script" ] && "$usage_script" 2>/dev/null | tail -2 | sed 's/^/  /' || echo "  (sem dados)"
