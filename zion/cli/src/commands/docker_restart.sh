# Reinicia um servico Docker.
zion_load_config

service="${args[service]}"
env="${args[--env]:-}"

project=$(zion_docker_project_name "$service")
compose=$(zion_docker_compose_file "$service")
log_dir=$(zion_docker_log_dir "$service")

# Parar logger
if [[ -f "$log_dir/logger.pid" ]]; then
  kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
  rm -f "$log_dir/logger.pid"
fi

echo "[zion docker] Parando $service..."
docker compose -f "$compose" -p "$project" down 2>/dev/null
docker compose -p "${project}-deps" down 2>/dev/null

# Re-levantar via zion docker run
restart_env="${env:-sand}"
echo "[zion docker] Reiniciando $service [env=$restart_env]..."
exec "$0" docker run "$service" --env="$restart_env" --detach
