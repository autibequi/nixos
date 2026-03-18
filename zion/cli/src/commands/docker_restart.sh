# Reinicia um servico Docker.
zion_load_config

service="${args[service]}"
env="${args[--env]:-}"
worktree="${args[--worktree]:-}"

zion_docker_init_worktree "$service" "$worktree" || exit 1

project=$(zion_docker_effective_project "$service")
compose=$(zion_docker_compose_file "$service")
log_dir=$(zion_docker_log_dir "$service")
[[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"

# Parar logger
if [[ -f "$log_dir/logger.pid" ]]; then
  kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
  rm -f "$log_dir/logger.pid"
fi

local_label="$service"
[[ -n "$_ZION_DK_WORKTREE" ]] && local_label="$service (wt: $_ZION_DK_WORKTREE)"

echo "[zion docker] Parando $local_label..."
docker compose -f "$compose" -p "$project" down 2>/dev/null
docker compose -p "${project}-deps" down 2>/dev/null

# Re-levantar via zion docker run
restart_env="${env:-sand}"
wt_flag=""
[[ -n "$worktree" ]] && wt_flag="--worktree=$worktree"
echo "[zion docker] Reiniciando $local_label [env=$restart_env]..."
exec "$0" docker run "$service" --env="$restart_env" --detach $wt_flag
