# Abre shell dentro do container de um servico Docker.
zion_load_config

service="${args[service]}"
container="${args[container]:-app}"

project=$(zion_docker_project_name "$service")
compose=$(zion_docker_compose_file "$service")

docker compose -f "$compose" -p "$project" exec "$container" /bin/sh
