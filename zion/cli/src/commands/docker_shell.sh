# Abre shell interativo ou executa comando com Go toolchain.
# Sem -c: exec no container rodando (app ou --container especificado).
# Com -c CMD: roda one-off dev container (golang:alpine + make) com source montado.

zion_load_config

service="${args[service]}"
container="${args[--container]:-app}"
cmd="${args[--cmd]}"
worktree="${args[--worktree]:-}"

zion_docker_validate_service "$service" || exit 1
zion_docker_init_worktree "$service" "$worktree" || exit 1

dir=$(zion_docker_effective_dir "$service")
project=$(zion_docker_effective_project "$service")
compose=$(zion_docker_compose_file "$service")

if [[ -n "$cmd" ]]; then
  # Modo dev: one-off container golang com source montado + make + ferramentas
  echo "=== [$service] exec: $cmd ==="
  [[ -n "$_ZION_DK_WORKTREE" ]] && echo "  worktree: $_ZION_DK_WORKTREE ($dir)"
  docker run \
    --rm \
    -it \
    -v "$dir:/go/app" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e GOPATH=/go \
    -e GOPRIVATE="github.com/estrategiahq" \
    -e TERM=xterm-256color \
    -e COLORTERM=truecolor \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -e TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock \
    --network nixos_default \
    -w "/go/app" \
    "golang:1.24.4-alpine" \
    sh -c "apk add --no-cache make gcc musl-dev librdkafka-dev ca-certificates docker-cli > /dev/null 2>&1 && $cmd"
else
  # Modo interativo: exec no container rodando
  docker compose -f "$compose" -p "$project" exec "$container" /bin/sh
fi
