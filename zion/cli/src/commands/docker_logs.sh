# Mostra logs de um servico Docker (reconecta se container esta rodando, le arquivo se parado).
zion_load_config

service="${args[service]}"
follow="${args[--follow]:-}"
tail_lines="${args[--tail]:-100}"

project=$(zion_docker_project_name "$service")
log_dir=$(zion_docker_log_dir "$service")
compose=$(zion_docker_compose_file "$service")

# Tentar reconectar ao container rodando
running=$(docker compose -f "$compose" -p "$project" ps --status running 2>/dev/null | tail -n +2 | wc -l)

if [[ "$running" -gt 0 ]]; then
  ARGS="--tail $tail_lines"
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
  echo "Use: zion docker run $service"
fi
