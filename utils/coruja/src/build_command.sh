# build — (re)builda as imagens.

service="${args[service]:-}"

if [[ -n "$service" ]]; then
  run_compose build "$service"
else
  run_compose build
fi
