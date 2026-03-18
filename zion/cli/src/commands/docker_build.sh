# Rebuilda a imagem Docker de um servico sem derrubar containers.

zion_load_config

service="${args[service]}"
worktree="${args[--worktree]:-}"

zion_docker_validate_service "$service" || exit 1
zion_docker_init_worktree "$service" "$worktree" || exit 1

zion_docker_export_dirs "$service"
export ZION_NIXOS_DIR="$zion_nixos_dir"

compose=$(zion_docker_compose_file "$service")
project=$(zion_docker_effective_project "$service")

echo "=== [docker build] $service ==="
docker compose -f "$compose" -p "$project" build --no-cache
echo ""
echo "Imagem rebuilt. Rode 'zion docker run $service' para subir."
