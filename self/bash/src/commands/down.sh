# Para todos os containers do projeto (zion sessions + puppy)
zion_load_config
compose_zion="${ZION_ROOT:-$HOME/nixos/self}/container/docker-compose.zion.yml"
compose_puppy="${ZION_ROOT:-$HOME/nixos/self}/container/docker-compose.puppy.yml"

echo "Stopping zion session containers..."
docker compose -f "$compose_zion" down 2>/dev/null || true

echo "Stopping puppy container..."
docker compose -f "$compose_puppy" down 2>/dev/null || true

echo "Done."
