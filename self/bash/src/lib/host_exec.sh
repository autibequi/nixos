# host_exec.sh — executa comandos no HOST via nsenter (Docker socket).
#
# Dentro do container, usa um container temporário com --pid=host + nsenter
# para rodar comandos no namespace do host. No host, executa diretamente.

_zion_host_exec() {
  if [[ "${CLAUDE_ENV:-}" != "container" ]]; then
    # No host: executar diretamente
    eval "$@"
    return $?
  fi

  local host_home="${HOST_HOME:-/home/pedrinho}"
  local host_user
  host_user=$(basename "$host_home")

  echo "[zion] Executando no host via nsenter..."
  docker run --rm -i \
    --privileged \
    --pid=host \
    --network=host \
    alpine:latest \
    nsenter -t 1 -m -u -i -n -- \
    su - "$host_user" -c "$*"
}
