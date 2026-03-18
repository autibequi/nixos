# Segue logs do daemon dentro do container puppy.
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

LOGFILE="/workspace/.ephemeral/logs/daemon.log"

if [[ -n "${args[--follow]:-}" ]]; then
  OBSIDIAN_PATH="$zion_obsidian_path" \
    docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
    exec -T puppy tail -f "$LOGFILE"
else
  OBSIDIAN_PATH="$zion_obsidian_path" \
    docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
    exec -T puppy cat "$LOGFILE" 2>/dev/null || echo "(sem logs — daemon ainda nao rodou)"
fi
