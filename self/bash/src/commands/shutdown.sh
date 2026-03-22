# Mata todos os containers relacionados ao Zion (compose + strays por nome)
# Util quando containers foram criados manualmente e nao estao no tracking do compose.

zion_load_config

compose_zion="${ZION_ROOT:-$HOME/nixos/self}/container/docker-compose.zion.yml"
compose_puppy="${ZION_ROOT:-$HOME/nixos/self}/container/docker-compose.puppy.yml"

echo "Stopping compose-tracked containers..."
docker compose -f "$compose_zion" down 2>/dev/null || true
docker compose -f "$compose_puppy" down 2>/dev/null || true

echo "Killing any stray zion/claude/puppy containers..."
stray=$(docker ps -a --format '{{.Names}}' 2>/dev/null \
  | grep -E 'zion|claude|leech|puppy' || true)

if [[ -n "$stray" ]]; then
  echo "$stray" | xargs docker rm -f
  echo "Removed: $stray"
else
  echo "  (none found)"
fi

echo "Done."
