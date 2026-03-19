# Roda 1 tick do scheduler imediatamente (para teste).
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

# Check container is running
if ! OBSIDIAN_PATH="$zion_obsidian_path" docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" ps --status running 2>/dev/null | grep -q puppy; then
  echo "[zion puppy] Container puppy nao esta rodando. Use: zion puppy start" >&2
  exit 1
fi

echo "[zion puppy] Rodando 1 tick do daemon..."
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
  exec -u claude -e PUPPY_SINGLE_TICK=1 -e SCHEDULER_VERBOSE=1 \
  puppy /workspace/zion/scripts/puppy-daemon.sh
