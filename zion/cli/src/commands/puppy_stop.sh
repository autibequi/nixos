# Stop puppy container
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

echo "Stopping puppy container..."
docker compose -f "$compose_file" down
echo "Puppy stopped."
