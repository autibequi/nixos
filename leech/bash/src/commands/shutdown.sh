# Mata todos os containers relacionados ao Leech (compose + strays por nome)
# Util quando containers foram criados manualmente e nao estao no tracking do compose.

leech_load_config

compose_leech="${LEECH_ROOT:-$HOME/nixos/self}/container/docker-compose.leech.yml"
compose_puppy="${LEECH_ROOT:-$HOME/nixos/self}/container/docker-compose.puppy.yml"

echo "Stopping compose-tracked containers..."
docker compose -f "$compose_leech" down 2>/dev/null || true
docker compose -f "$compose_puppy" down 2>/dev/null || true

echo "Killing any stray leech/claude/puppy containers..."
stray=$(docker ps -a --format '{{.Names}}' 2>/dev/null \
  | grep -E 'leech|claude|leech|puppy' || true)

if [[ -n "$stray" ]]; then
  echo "$stray" | xargs docker rm -f
  echo "Removed: $stray"
else
  echo "  (none found)"
fi

echo "Done."
