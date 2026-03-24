# docker_shell_impl.sh — abre shell interativo ou executa comando.
# Monolito: one-off container golang:alpine com source montado + toolchain.
# Node (bo-container, front-student): docker exec no container rodando com sh -l.
#
# Uso: _leech_dk_shell <service> <container> <cmd> <worktree>

_leech_dk_shell() {
  local service="$1"
  local container="${2:-app}"
  local cmd="${3:-}"
  local worktree="${4:-}"

  leech_docker_validate_service "$service" || return 1
  leech_docker_init_worktree "$service" "$worktree" || return 1

  # Exportar e fixar paths para container→host translation
  leech_docker_export_dirs "$service"
  _leech_dk_container_fixup

  local dir project compose
  dir=$(leech_docker_effective_dir "$service")
  project=$(leech_docker_effective_project "$service")
  compose=$(leech_docker_compose_file "$service")

  # Serviços Node: exec no container rodando (tem npm, node_modules/.bin no PATH via sh -l)
  if [[ "$service" == "bo-container" || "$service" == "front-student" ]]; then
    local container_name="${project}-${container}"
    if [[ -n "$cmd" ]]; then
      echo "=== [$service] exec: $cmd ==="
      docker exec -it "$container_name" sh -l -c "$cmd"
    else
      docker exec -it "$container_name" sh -l
    fi
    return $?
  fi

  # Monolito: one-off container golang com source montado + make + ferramentas
  if [[ -n "$cmd" ]]; then
    local host_uid host_gid log_dir log_file
    host_uid="$(id -u)"
    host_gid="$(id -g)"
    log_dir="$(leech_docker_log_dir "$service")"
    [[ -n "$_LEECH_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_LEECH_DK_WORKTREE}"
    log_file="$log_dir/test.log"
    leech_ensure_log_dir "$log_dir"

    echo "=== [$service] exec: $cmd ===" | tee "$log_file"
    [[ -n "$_LEECH_DK_WORKTREE" ]] && echo "  worktree: $_LEECH_DK_WORKTREE ($dir)" | tee -a "$log_file"
    echo "  logs: $log_file"
    docker run \
      --rm \
      -i \
      -v "$dir:/go/app" \
      -v "$log_dir:/workspace/logs" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "leech-go-mod-cache:/go/pkg/mod" \
      -v "leech-go-build-cache:/root/.cache/go-build" \
      -e GOPATH=/go \
      -e GOPRIVATE="github.com/estrategiahq" \
      -e TERM=xterm-256color \
      -e COLORTERM=truecolor \
      -e DOCKER_HOST=unix:///var/run/docker.sock \
      -e TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock \
      -e HOST_UID="$host_uid" \
      -e HOST_GID="$host_gid" \
      --network host \
      -w "/go/app" \
      "golang:1.24.4-alpine" \
      sh -c "apk add --no-cache make gcc musl-dev librdkafka-dev ca-certificates docker-cli > /dev/null 2>&1 && $cmd && chown -R \"$HOST_UID:$HOST_GID\" /go/app 2>/dev/null || true" 2>&1 | tee -a "$log_file"
  else
    local host_uid host_gid log_dir
    host_uid="$(id -u)"
    host_gid="$(id -g)"
    log_dir="$(leech_docker_log_dir "$service")"
    leech_ensure_log_dir "$log_dir"

    docker run \
      --rm \
      -it \
      -v "$dir:/go/app" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "leech-go-mod-cache:/go/pkg/mod" \
      -v "leech-go-build-cache:/root/.cache/go-build" \
      -e GOPATH=/go \
      -e GOPRIVATE="github.com/estrategiahq" \
      -e TERM=xterm-256color \
      -e COLORTERM=truecolor \
      -e DOCKER_HOST=unix:///var/run/docker.sock \
      -e TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock \
      -e HOST_UID="$host_uid" \
      -e HOST_GID="$host_gid" \
      --network host \
      -w "/go/app" \
      "golang:1.24.4-alpine" \
      sh -c "apk add --no-cache make gcc musl-dev librdkafka-dev ca-certificates docker-cli bash > /dev/null 2>&1 && exec sh"
  fi
}
