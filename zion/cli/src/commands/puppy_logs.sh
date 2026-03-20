# Show logs from the puppy container
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"
local follow="${args[--follow]:-}"

local flags=""
[ -n "$follow" ] && flags="-f"

docker compose -f "$compose_file" logs $flags puppy
