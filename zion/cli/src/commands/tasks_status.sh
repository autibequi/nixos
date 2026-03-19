# Show task execution log from inside puppy container
local lines="${args[--lines]:-20}"
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

docker compose -f "$compose_file" exec -T puppy bash -c "
  LOG=/workspace/obsidian/tasks/log.md
  if [ ! -f \$LOG ]; then echo 'No task log found'; exit 0; fi
  echo '=== Task Log (last $lines) ==='
  tail -n $lines \$LOG
" 2>/dev/null || {
  echo "Puppy container not running. Start with: zion puppy start"
  exit 1
}
