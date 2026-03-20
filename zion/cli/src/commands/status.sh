# Status agregado: sessões, docker services e tasks
zion_load_config
local compose_zion="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.zion.yml"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
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
echo "--- Tick (systemd) ---"
systemctl --user status zion-tick.timer 2>/dev/null | grep -E "Active|Trigger" | sed 's/^/  /' \
  || systemctl status zion-tick.timer 2>/dev/null | grep -E "Active|Trigger" | sed 's/^/  /' \
  || echo "  (timer nao encontrado — rode: nh os switch)"

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
