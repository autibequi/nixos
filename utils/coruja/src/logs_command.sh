# logs — tail dos logs (filtra por serviço opcional).

service="${args[service]:-}"
tail_n="${args[--tail]:-200}"

if [[ -n "$service" ]]; then
  run_compose logs -f --tail "$tail_n" "$service"
else
  run_compose logs -f --tail "$tail_n"
fi
