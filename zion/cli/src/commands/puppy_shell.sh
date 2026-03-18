# Abre bash dentro do container puppy.
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" exec -it puppy /bin/bash
