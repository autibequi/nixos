# Para um servico Docker e seus deps.
zion_load_config

service="${args[service]}"

zion_docker_validate_service "$service" || exit 1

project=$(zion_docker_project_name "$service")
log_dir=$(zion_docker_log_dir "$service")

# Parar logger persistente
if [[ -f "$log_dir/logger.pid" ]]; then
  kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
  rm -f "$log_dir/logger.pid"
fi

echo "[zion docker] Parando $service..."
docker compose -p "$project" down 2>/dev/null
docker compose -p "${project}-deps" down 2>/dev/null

echo "Servico $service parado."

# Derrubar reverse proxy se nenhum servico estrategia continua rodando
zion_docker_stop_reverseproxy_if_idle
