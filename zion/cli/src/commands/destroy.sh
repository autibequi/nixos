# Para containers, remove imagens e volumes do projeto
zion_load_config
compose_zion="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.zion.yml"

echo "Destroying zion session containers + volumes..."
docker compose -f "$compose_zion" down --volumes --remove-orphans 2>/dev/null || true

echo "Removing claude-nix-sandbox image..."
docker image rm claude-nix-sandbox 2>/dev/null || echo "  (image not found or in use)"

echo "Done."
