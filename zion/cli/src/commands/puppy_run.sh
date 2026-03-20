zion_load_config
# Run a task card inside the puppy container (by filename or name match)
local task="${args[task]}"
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

# Check puppy is running
if ! docker compose -f "$compose_file" ps --status running 2>/dev/null | grep -q puppy; then
  echo "Puppy container not running. Start with: zion puppy start"
  exit 1
fi

# Clear stale locks and find card inside container
docker compose -f "$compose_file" exec -T -u claude puppy \
  bash -c "rm -rf /tmp/zion-locks/ 2>/dev/null; mkdir -p /tmp/zion-locks" 2>/dev/null || true

local card=""
card=$(docker compose -f "$compose_file" exec -T -u claude puppy \
  bash -c "for f in /workspace/obsidian/tasks/TODO/*_${task}.md /workspace/obsidian/tasks/DOING/*_${task}.md; do [ -f \"\$f\" ] && basename \"\$f\" && break; done" 2>/dev/null || true)

if [ -z "$card" ]; then
  echo "Card '$task' not found in TODO/ or DOING/"
  echo "Available:"
  docker compose -f "$compose_file" exec -T -u claude puppy \
    bash -c "ls /workspace/obsidian/tasks/TODO/ 2>/dev/null | sed 's/^/  TODO: /'" 2>/dev/null || true
  exit 1
fi

echo "Running: $card"
docker compose -f "$compose_file" exec -u claude puppy \
  /workspace/zion/scripts/task-runner.sh "$card"
