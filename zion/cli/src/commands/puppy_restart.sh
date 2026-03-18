# Reinicia o container puppy (stop + start).
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

echo "[zion puppy] Parando container..."
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" down 2>/dev/null || true

if ! docker network inspect nixos_default &>/dev/null; then
  docker network create nixos_default 2>/dev/null || true
fi

echo "[zion puppy] Subindo container puppy..."
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" up -d puppy

echo "[zion puppy] Iniciando daemon interno..."
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
  exec -d puppy /bin/bash -c "/workspace/zion/scripts/puppy-daemon.sh"

echo "[zion puppy] Reiniciado."
