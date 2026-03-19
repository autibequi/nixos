# Run a specific task inside the puppy container
local task="${args[task]}"

# Find source directory
local source="backlog"
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

echo "Running task: $task"
docker compose -f "$compose_file" exec puppy \
  /workspace/zion/scripts/task-runner.sh "$task" "$source"
