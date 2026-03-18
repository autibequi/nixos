# Inicia o container puppy persistente e o daemon interno.
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

if ! docker network inspect nixos_default &>/dev/null; then
  echo "[zion puppy] Criando rede nixos_default..."
  docker network create nixos_default 2>/dev/null || true
fi

echo "[zion puppy] Subindo container puppy..."
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" up -d puppy

echo "[zion puppy] Iniciando daemon interno..."
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" \
  exec -d puppy /bin/bash -c "/zion/scripts/puppy-daemon.sh"

echo "[zion puppy] Container puppy + daemon iniciados."
