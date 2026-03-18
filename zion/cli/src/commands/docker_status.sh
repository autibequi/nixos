# Status dos servicos Docker.
zion_load_config

service="${args[service]:-}"

if [[ -n "$service" ]]; then
  project=$(zion_docker_project_name "$service")
  compose=$(zion_docker_compose_file "$service")
  echo "=== $service ==="
  docker compose -f "$compose" -p "$project" ps 2>/dev/null || echo "$service: nao encontrado"
  docker compose -p "${project}-deps" ps 2>/dev/null
else
  echo "=== Servicos Docker Zion ==="
  for svc in monolito bo-container front-student; do
    project=$(zion_docker_project_name "$svc")
    compose=$(zion_docker_compose_file "$svc")
    running=$(docker compose -f "$compose" -p "$project" ps --status running 2>/dev/null | tail -n +2 | wc -l)
    deps_running=$(docker compose -p "${project}-deps" ps --status running 2>/dev/null | tail -n +2 | wc -l)
    total=$((running + deps_running))
    if [[ "$total" -gt 0 ]]; then
      echo "  $svc: $running services + $deps_running deps rodando"
    else
      echo "  $svc: parado"
    fi
  done
fi
