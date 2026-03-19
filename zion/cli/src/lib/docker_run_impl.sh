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

  local COMPOSE_ARGS="-f $compose -p $project"
  if [[ -n "$debug" ]]; then
    local debug_compose
    debug_compose=$(dirname "$compose")/docker-compose.debug.yml
    COMPOSE_ARGS="$COMPOSE_ARGS -f $debug_compose"
  fi

  _zion_progress_init

  local title="docker run  $service  [env=$env]"
  [[ -n "$debug" ]] && title="$title  [DEBUG :2345]"
  _zion_header "$title"

  local has_deps=0
  [[ -f "$deps_compose" ]] && has_deps=1

  local total=4
  [[ $has_deps -eq 1 ]] && total=6

  # step 1: parar instancia anterior + liberar portas
  _stop_prev() {
    _zion_dk_stop "$service" "$worktree" 2>/dev/null || true
    for port in $(zion_docker_service_host_ports "$service"); do
      zion_docker_free_port "$port"
    done
  }

  # step 2: garantir rede + reverse proxy
  _ensure_network() {
    docker network inspect nixos_default &>/dev/null \
      || docker network create nixos_default 2>/dev/null || true
    zion_docker_ensure_reverseproxy
  }

  local step=0
  step=$((step + 1)); _zion_step $step $total "Parando instância anterior" _stop_prev     || return 1
  step=$((step + 1)); _zion_step $step $total "Rede + reverse proxy"       _ensure_network || return 1

  # step 3+4 (opcionais): deps
  if [[ $has_deps -eq 1 ]]; then
    _start_deps() {
      docker compose -f "$deps_compose" -p "${project}-deps" up -d --remove-orphans \
        > "$log_dir/deps.log" 2>&1
    }
    _wait_postgres() {
      until docker exec zion-dk-monolito-postgres \
          pg_isready -U "${DB_USER:-estrategia}" &>/dev/null; do
        sleep 1
      done
    }
    step=$((step + 1)); _zion_step $step $total "Subindo dependências"   _start_deps    || return 1
    step=$((step + 1)); _zion_step $step $total "Aguardando Postgres"    _wait_postgres || return 1
  fi

  # build
  _build_svc() {
    DOCKER_BUILDKIT=1 docker compose $COMPOSE_ARGS build > "$log_dir/startup.log" 2>&1
  }
  step=$((step + 1)); _zion_step $step $total "Building image" _build_svc || return 1

  # up + logger
  _start_svc() {
    docker compose $COMPOSE_ARGS up -d --force-recreate --remove-orphans \
      >> "$log_dir/startup.log" 2>&1
    [[ -f "$log_dir/logger.pid" ]] && kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
    nohup docker compose $COMPOSE_ARGS logs -f --no-log-prefix \
      > "$log_dir/service.log" 2>&1 &
    echo $! > "$log_dir/logger.pid"
  }
  step=$((step + 1)); _zion_step $step $total "Iniciando container" _start_svc || return 1

  _zion_done

  if [[ -n "$debug" ]]; then
    printf "  \033[33m[DEBUG]\033[0m Delve aguardando attach em localhost:2345\n"
    printf "  \033[33m[DEBUG]\033[0m VS Code: use a config 'Attach to monolito'\n\n"
  fi

  # detach: sair sem seguir logs
  if [[ -n "$detach" ]]; then
    printf "  \033[2mLogs: zion docker %s logs -f\033[0m\n" "$service"
    printf "  \033[2mArquivo: %s/service.log\033[0m\n\n" "$log_dir"
    return 0
  fi

  # seguir logs ao vivo (Ctrl+C sai mas container continua)
  printf "  \033[2m[Ctrl+C para sair — container continua] reconectar: zion docker %s logs -f\033[0m\n" "$service"
  printf "  \033[2m%s\033[0m\n\n" "─────────────────────────────────────────"
  docker compose $COMPOSE_ARGS logs -f --no-log-prefix --tail 50
}
