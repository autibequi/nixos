zion_load_config
# Run a task card inside the puppy container (by filename or name match)
local task="${args[task]}"
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

# If no .md extension, search TODO/ for matching card
if [[ "$task" != *.md ]]; then
  local match=""
  match=$(docker compose -f "$compose_file" exec -T puppy \
    bash -c "ls /workspace/obsidian/tasks/TODO/*_${task}.md /workspace/obsidian/tasks/DOING/*_${task}.md 2>/dev/null | head -1 | xargs basename" 2>/dev/null || true)
  if [ -n "$match" ]; then
    task="$match"
  else
    task="${task}.md"
  fi
fi

echo "Running: $task"
docker compose -f "$compose_file" exec puppy \
  /workspace/zion/scripts/task-runner.sh "$task"
