# Open interactive bash inside puppy container
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"

docker compose -f "$compose_file" exec puppy bash
