# docker_run_impl.sh — levanta um servico Docker em background e abre logs.
#
# Uso: _zion_dk_run <service> <env> <debug> <worktree> <vertical> <detach>

_zion_dk_run() {
  local service="$1"
  local env="${2:-sand}"
  local debug="${3:-}"
  local worktree="${4:-}"
  local vertical="${5:-carreiras-juridicas}"
  local detach="${6:-}"

  zion_docker_validate_service "$service" || return 1
  zion_docker_init_worktree "$service" "$worktree" || return 1

  local dir config_dir compose deps_compose env_file project log_dir
  dir=$(zion_docker_effective_dir "$service")
  config_dir=$(zion_docker_config_dir "$service")
  compose=$(zion_docker_compose_file "$service")
  deps_compose=$(zion_docker_deps_file "$service")
  env_file=$(zion_docker_env_file "$service" "$env")
  project=$(zion_docker_effective_project "$service")
  log_dir=$(zion_docker_log_dir "$service")
  [[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"

  zion_ensure_log_dir "$log_dir"

  # Exportar variaveis que o compose precisa (com override de worktree)
  zion_docker_export_dirs "$service"
  _zion_dk_container_fixup
  export ZION_NIXOS_DIR="$zion_nixos_dir"
  export APP_ENV="$env"

  # Mapear env para sufixo do arquivo .env do projeto
  case "$env" in
    sand)   export APP_ENV_FILE="sandbox" ;;
    local)  export APP_ENV_FILE="local" ;;
    devbox) export APP_ENV_FILE="devbox" ;;
    *)      export APP_ENV_FILE="$env" ;;
  esac

  # Mapear env para nome do npm script (front-student usa devbox/qa/prod)
  case "$env" in
    sand|local) export NPM_SCRIPT_ENV="devbox" ;;
    *)          export NPM_SCRIPT_ENV="$env" ;;
  esac

  # Vertical (front-student: carreiras-juridicas, concursos, medicina, etc.)
  export VERTICAL="${vertical:-carreiras-juridicas}"

  # Garantir rede
  if ! docker network inspect nixos_default &>/dev/null; then
    echo "[zion docker] Criando rede nixos_default..."
    docker network create nixos_default 2>/dev/null || true
  fi

  local COMPOSE_ARGS="-f $compose -p $project"
  if [[ -n "$debug" ]]; then
    local debug_compose
    debug_compose=$(dirname "$compose")/docker-compose.debug.yml
    COMPOSE_ARGS="$COMPOSE_ARGS -f $debug_compose"
  fi

  if [[ -n "$debug" ]]; then
    echo "=== Levantando $service [env=$env] [DEBUG - dlv :2345] ==="
  else
    echo "=== Levantando $service [env=$env] ==="
  fi
  echo "  projeto: $dir"
  [[ -n "$_ZION_DK_WORKTREE" ]] && echo "  worktree: $_ZION_DK_WORKTREE"
  echo "  compose: $compose"
  echo "  env:     $env_file"
  echo "  logs:    $log_dir"

  # Parar instancia anterior do mesmo servico (libera porta, evita "port already allocated")
  _zion_dk_stop "$service" "$worktree" 2>/dev/null || true
  # Fallback: parar qualquer container que ainda esteja segurando a(s) porta(s) do servico
  for port in $(zion_docker_service_host_ports "$service"); do
    zion_docker_free_port "$port"
  done

  # 0. Garantir reverse proxy (80/443 -> 4004)
  zion_docker_ensure_reverseproxy

  # 1. Subir dependencias em background (se compose de deps existe)
  if [[ -f "$deps_compose" ]]; then
    echo ">>> Subindo dependencias..."
    docker compose -f "$deps_compose" -p "${project}-deps" up -d --remove-orphans 2>&1 | tee "$log_dir/deps.log"
    echo ">>> Aguardando postgres ficar saudavel..."
    until docker exec zion-dk-monolito-postgres pg_isready -U "${DB_USER:-estrategia}" &>/dev/null; do
      sleep 1
    done
    echo ">>> Postgres pronto."
  fi

  # 2. Build + subir servico em background (com SSH forwarding para repos privados)
  echo ">>> Subindo $service..."
  DOCKER_BUILDKIT=1 docker compose $COMPOSE_ARGS build 2>&1 | tee "$log_dir/startup.log"
  docker compose $COMPOSE_ARGS up -d --force-recreate --remove-orphans 2>&1 | tee -a "$log_dir/startup.log"

  # 3. Logger persistente: grava logs em arquivo continuamente
  if [[ -f "$log_dir/logger.pid" ]]; then
    kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
  fi
  nohup docker compose $COMPOSE_ARGS logs -f --no-log-prefix > "$log_dir/service.log" 2>&1 &
  if [[ -n "$debug" ]]; then
    echo ">>> [DEBUG] Delve aguardando attach em localhost:2345"
    echo ">>> [DEBUG] VS Code: use a config 'Attach to monolito' (porta 2345)"
  fi
  echo $! > "$log_dir/logger.pid"

  # 4. Se --detach, sair silenciosamente
  if [[ -n "$detach" ]]; then
    echo ">>> Container rodando em background."
    echo ">>> Logs: zion docker $service logs -f"
    echo ">>> Arquivo: $log_dir/service.log"
    return 0
  fi

  # 5. Mostrar logs no terminal (Ctrl+C sai mas container + logger continuam)
  echo ">>> Container rodando. Logs em tempo real [Ctrl+C para sair, container continua]:"
  echo ">>> Reconectar: zion docker $service logs -f"
  echo "---"
  docker compose $COMPOSE_ARGS logs -f --no-log-prefix --tail 50
}
