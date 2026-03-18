# docker_shell_impl.sh — abre shell interativo ou executa comando com Go toolchain.
# Sem cmd: exec no container rodando (app ou container especificado).
# Com cmd: roda one-off dev container (golang:alpine + make) com source montado.
#
# Uso: _zion_dk_shell <service> <container> <cmd> <worktree>

_zion_dk_shell() {
  local service="$1"
  local container="${2:-app}"
  local cmd="${3:-}"
  local worktree="${4:-}"

  zion_docker_validate_service "$service" || return 1
  zion_docker_init_worktree "$service" "$worktree" || return 1

  local dir project compose
  dir=$(zion_docker_effective_dir "$service")
  project=$(zion_docker_effective_project "$service")
  compose=$(zion_docker_compose_file "$service")

  if [[ -n "$cmd" ]]; then
    # Modo dev: one-off container golang com source montado + make + ferramentas
    local host_uid host_gid log_dir log_file
    host_uid="$(id -u)"
    host_gid="$(id -g)"
    log_dir="$(zion_docker_log_dir "$service")"
    [[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"
    log_file="$log_dir/test.log"
    zion_ensure_log_dir "$log_dir"

    echo "=== [$service] exec: $cmd ===" | tee "$log_file"
    [[ -n "$_ZION_DK_WORKTREE" ]] && echo "  worktree: $_ZION_DK_WORKTREE ($dir)" | tee -a "$log_file"
    echo "  logs: $log_file"
    docker run \
      --rm \
      -i \
      -v "$dir:/go/app" \
      -v "$log_dir:/workspace/logs" \
      -v /var/run/docker.sock:/var/run/docker.sock \
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
    # Modo interativo: exec no container rodando
    docker compose -f "$compose" -p "$project" exec "$container" /bin/sh
  fi
}
