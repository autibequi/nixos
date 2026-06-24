# restart — recria container(s) com --force-recreate.
# Recarrega a config do último `up` (.coruja-state) e re-exporta o ambiente; sem isso
# o container recriado cairia nos defaults do compose (vertical, ambiente do monolito, SSL).

service="${args[service]:-}"

load_env_from_state

if [[ -n "$service" ]]; then
  run_compose up -d --force-recreate "$service"
else
  run_compose up -d --force-recreate
fi
