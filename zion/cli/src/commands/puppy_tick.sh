zion_load_config
# Run a single tick of the task-daemon (for testing)
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

echo "Running single tick..."
docker compose -f "$compose_file" exec -u claude -e PUPPY_SINGLE_TICK=1 puppy \
  /workspace/zion/scripts/task-daemon.sh
