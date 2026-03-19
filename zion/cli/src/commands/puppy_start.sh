# Start puppy container with task-daemon
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

if [ ! -f "$compose_file" ]; then
  echo "Compose file not found: $compose_file"
  exit 1
fi

echo "Starting puppy container (task-daemon)..."
docker compose -f "$compose_file" up -d
echo "Puppy started. Use 'zion puppy logs -f' to follow."
