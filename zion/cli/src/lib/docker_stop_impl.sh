# docker_stop_impl.sh — para um servico Docker e seus deps.
#
# Uso: _zion_dk_stop <service> <worktree>

_zion_dk_stop() {
  local service="$1"
  local worktree="${2:-}"

  zion_docker_validate_service "$service" || return 1
  zion_docker_init_worktree "$service" "$worktree" || return 1

  local compose deps_compose project log_dir
  compose=$(zion_docker_compose_file "$service")
  deps_compose=$(zion_docker_deps_file "$service")
  project=$(zion_docker_effective_project "$service")
  log_dir=$(zion_docker_log_dir "$service")
  [[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"

  # Parar logger persistente
  if [[ -f "$log_dir/logger.pid" ]]; then
    kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
    rm -f "$log_dir/logger.pid"
  fi

  local local_label="$service"
  [[ -n "$_ZION_DK_WORKTREE" ]] && local_label="$service (wt: $_ZION_DK_WORKTREE)"

  echo "[zion docker] Parando $local_label..."
  docker compose -f "$compose" -p "$project" down 2>/dev/null
  [[ -f "$deps_compose" ]] && docker compose -f "$deps_compose" -p "${project}-deps" down 2>/dev/null

  echo "Servico $local_label parado."

  # Derrubar reverse proxy se nenhum servico estrategia continua rodando
  zion_docker_stop_reverseproxy_if_idle
}
