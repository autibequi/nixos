# Show puppy container status and recent task log
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

echo "=== Container ==="
docker compose -f "$compose_file" ps puppy 2>/dev/null || echo "  (not running)"

echo ""
echo "=== Recent tasks (last 20) ==="
docker compose -f "$compose_file" exec -T -u claude puppy \
  bash -c "tail -20 /workspace/obsidian/tasks/log.md 2>/dev/null || echo '  (no log yet)'" 2>/dev/null || \
  echo "  (container not running)"
