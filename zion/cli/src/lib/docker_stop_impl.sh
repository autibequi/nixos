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

  local local_label="$service"
  [[ -n "$_ZION_DK_WORKTREE" ]] && local_label="$service (wt: $_ZION_DK_WORKTREE)"

  _zion_progress_init
  _zion_header "docker stop  $local_label"

  local total=3
  [[ -f "$deps_compose" ]] && total=4

  _stop_logger() {
    if [[ -f "$log_dir/logger.pid" ]]; then
      kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
      rm -f "$log_dir/logger.pid"
    fi
  }

  _stop_service() { docker compose -f "$compose" -p "$project" down 2>/dev/null; }
  _stop_deps()    { docker compose -f "$deps_compose" -p "${project}-deps" down 2>/dev/null; }
  _stop_proxy()   { zion_docker_stop_reverseproxy_if_idle; }

  local step=0
  step=$((step + 1)); _zion_step $step $total "Parando logger"  _stop_logger
  step=$((step + 1)); _zion_step $step $total "Parando serviço" _stop_service
  if [[ -f "$deps_compose" ]]; then
    step=$((step + 1)); _zion_step $step $total "Parando deps" _stop_deps
  fi
  step=$((step + 1)); _zion_step $step $total "Reverse proxy"  _stop_proxy

  _zion_done
}
