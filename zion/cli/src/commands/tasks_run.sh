# Run a task card by name inside puppy container
local name="${args[name]}"
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

# Check puppy is running
if ! docker compose -f "$compose_file" ps --status running 2>/dev/null | grep -q puppy; then
  echo "Puppy container not running. Start with: zion puppy start"
  exit 1
fi

# Find and run card inside container
docker compose -f "$compose_file" exec puppy \
  bash -c "
    TASKS=/workspace/obsidian/tasks
    echo \"[debug] /workspace/obsidian contents:\" >&2
    ls /workspace/obsidian/ >&2 2>/dev/null || echo '  (empty or not mounted)' >&2
    echo \"[debug] TODO/ contents:\" >&2
    ls \$TASKS/TODO/ >&2 2>/dev/null || echo '  (empty)' >&2
    CARD=''
    for f in \$TASKS/TODO/*_${name}.md \$TASKS/DOING/*_${name}.md; do
      [ -f \"\$f\" ] && CARD=\$(basename \"\$f\") && break
    done
    if [ -z \"\$CARD\" ]; then
      echo \"Card '${name}' not found in TODO/ or DOING/\"
      exit 1
    fi
    echo \"Running: \$CARD\"
    exec /workspace/zion/scripts/task-runner.sh \"\$CARD\"
  "
