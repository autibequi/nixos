# Restart puppy container (recreate to pick up new config/mounts)
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

echo "Restarting puppy container..."
docker compose -f "$compose_file" down
docker compose -f "$compose_file" up -d
echo "Puppy restarted. Use 'zion puppy logs -f' to follow."
