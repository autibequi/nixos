# Para um servico Docker e seus deps.
zion_load_config

service="${args[service]}"
worktree="${args[--worktree]:-}"

zion_docker_validate_service "$service" || exit 1
zion_docker_init_worktree "$service" "$worktree" || exit 1

project=$(zion_docker_effective_project "$service")
log_dir=$(zion_docker_log_dir "$service")
[[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"

# Parar logger persistente
if [[ -f "$log_dir/logger.pid" ]]; then
  kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
  rm -f "$log_dir/logger.pid"
fi

local_label="$service"
[[ -n "$_ZION_DK_WORKTREE" ]] && local_label="$service (wt: $_ZION_DK_WORKTREE)"

echo "[zion docker] Parando $local_label..."
docker compose -p "$project" down 2>/dev/null
docker compose -p "${project}-deps" down 2>/dev/null

echo "Servico $local_label parado."

# Derrubar reverse proxy se nenhum servico estrategia continua rodando
zion_docker_stop_reverseproxy_if_idle
