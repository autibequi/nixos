# Run a task card by name inside puppy container
local name="${args[name]}"
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

# Check puppy is running
if ! docker compose -f "$compose_file" ps --status running 2>/dev/null | grep -q puppy; then
  echo "Puppy container not running. Start with: zion puppy start"
  exit 1
fi

# Clear stale locks for this task
docker compose -f "$compose_file" exec -T puppy \
  bash -c "rm -rf /tmp/zion-locks/*${name}* 2>/dev/null || true" 2>/dev/null || true

# Find and run card inside container
docker compose -f "$compose_file" exec -u claude puppy \
  bash -c "
    TASKS=/workspace/obsidian/tasks
    CARD=''
    for f in \$TASKS/TODO/*_${name}.md \$TASKS/DOING/*_${name}.md; do
      [ -f \"\$f\" ] && CARD=\$(basename \"\$f\") && break
    done
    if [ -z \"\$CARD\" ]; then
      echo \"Card '${name}' not found in TODO/ or DOING/\"
      echo 'Available:'
      ls \$TASKS/TODO/ 2>/dev/null | sed 's/^/  TODO: /'
      ls \$TASKS/DOING/ 2>/dev/null | sed 's/^/  DOING: /'
      exit 1
    fi
    exec /workspace/zion/scripts/task-runner.sh \"\$CARD\"
  "
