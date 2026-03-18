# Remove tudo relacionado a um servico Docker: containers, imagens, volumes, logs, vendor.

zion_load_config

service="${args[service]}"

zion_docker_validate_service "$service" || exit 1

dir=$(zion_docker_service_dir "$service")
config_dir=$(zion_docker_config_dir "$service")
compose=$(zion_docker_compose_file "$service")
deps_compose=$(zion_docker_deps_file "$service")
project=$(zion_docker_project_name "$service")
log_dir=$(zion_docker_log_dir "$service")

echo "=== Flush: $service ==="
echo "  containers + imagens + volumes"
echo "  logs: $log_dir"
[[ "$service" == "monolito" || "$service" == "monolito-worker" ]] && echo "  vendor: $dir/vendor"
echo ""

# 1. Parar logger se rodando
if [[ -f "$log_dir/logger.pid" ]]; then
  kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
  rm -f "$log_dir/logger.pid"
fi

# 2. Derrubar containers + remover volumes
echo ">>> Parando containers..."
docker compose -f "$compose" -p "$project" down -v --remove-orphans 2>/dev/null || true
docker compose -p "${project}-deps" down -v --remove-orphans 2>/dev/null || true

# 3. Remover imagens buildadas para este servico
echo ">>> Removendo imagens..."
docker images --filter "label=com.docker.compose.project=$project" -q | xargs docker rmi -f 2>/dev/null || true
# Tambem tenta por nome do container
docker rmi -f "zion-dk-${service}-app" "zion-dk-${service}-worker" 2>/dev/null || true

# 4. Remover volumes nomeados
echo ">>> Removendo volumes..."
docker volume ls --filter "label=com.docker.compose.project=$project" -q | xargs docker volume rm 2>/dev/null || true

# 5. Limpar logs
echo ">>> Limpando logs..."
rm -rf "$log_dir"

# 6. Remover vendor (se Go project)
if [[ -d "$dir/vendor" ]]; then
  echo ">>> Removendo vendor/..."
  rm -rf "$dir/vendor"
fi

echo ""
echo "Flush concluido. Rode 'zion docker install $service' para reinstalar."
