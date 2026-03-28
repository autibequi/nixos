# Para containers, remove imagens e volumes do projeto
leech_load_config
compose_leech="$leech_compose_file"
compose_puppy="${leech_container_dir}/docker-compose.puppy.yml"

echo "Destroying leech session containers + volumes..."
docker compose -f "$compose_leech" down --volumes --remove-orphans 2>/dev/null || true

echo "Destroying puppy container + volumes..."
docker compose -f "$compose_puppy" down --volumes --remove-orphans 2>/dev/null || true

echo "Removing leech image..."
docker image rm leech 2>/dev/null || echo "  (image not found or in use)"

echo "Done."
