# shell — abre um shell no container.

service="${args[service]}"
run_compose exec "$service" sh
