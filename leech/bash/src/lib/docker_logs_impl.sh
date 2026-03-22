# docker_logs_impl.sh — mostra logs de um servico Docker.
# Reconecta se container esta rodando, le arquivo se parado.
#
# Uso: _leech_dk_logs <service> <follow> <tail> <worktree>

_leech_dk_logs() {
  local service="$1"
  local follow="${2:-}"
  local tail_lines="${3:-100}"
  local worktree="${4:-}"

  leech_docker_init_worktree "$service" "$worktree" || return 1

  local project log_dir compose
  project=$(leech_docker_effective_project "$service")
  log_dir=$(leech_docker_log_dir "$service")
  [[ -n "$_LEECH_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_LEECH_DK_WORKTREE}"
  compose=$(leech_docker_compose_file "$service")

  # Tentar reconectar ao container rodando
  local running
  running=$(docker compose -f "$compose" -p "$project" ps --status running 2>/dev/null | tail -n +2 | wc -l)

  if [[ "$running" -gt 0 ]]; then
    local ARGS="--tail $tail_lines"
    [[ -n "$follow" ]] && ARGS="$ARGS -f"
    docker compose -f "$compose" -p "$project" logs --no-log-prefix $ARGS
  elif [[ -f "$log_dir/service.log" ]]; then
    echo "=== Container parado. Mostrando log gravado ==="
    if [[ -n "$follow" ]]; then
      tail -f "$log_dir/service.log"
    else
      tail -n "$tail_lines" "$log_dir/service.log"
    fi
  else
    echo "Nenhum container rodando e nenhum log encontrado para $service"
    echo "Use: leech docker $service server start"
  fi
}
