# Registry de servicos Docker conhecidos.
# Paths dos projetos vem de ~/.zion (ex: MONOLITO_DIR=...)
# Configs Docker versionadas em zion/dockerized/<service>/

# Diretorio do source do projeto (de ~/.zion)
zion_docker_service_dir() {
  local service="$1"
  local var_name
  case "$service" in
    monolito)         var_name="MONOLITO_DIR" ;;
    monolito-worker)  var_name="MONOLITO_DIR" ;;
    bo-container)     var_name="BO_CONTAINER_DIR" ;;
    front-student)    var_name="FRONT_STUDENT_DIR" ;;
    *) echo ""; return 1 ;;
  esac
  local dir="${!var_name}"
  [[ -z "$dir" ]] && dir="$HOME/projects/estrategia/$service"
  echo "$dir"
}

# Diretorio da config Docker versionada (neste repo)
# monolito-worker aponta pro mesmo dir do monolito
zion_docker_config_dir() {
  local service="$1"
  case "$service" in
    monolito-worker) echo "${zion_nixos_dir}/zion/dockerized/monolito" ;;
    *)               echo "${zion_nixos_dir}/zion/dockerized/${service}" ;;
  esac
}

# Compose principal do servico (versionado)
zion_docker_compose_file() {
  local service="$1"
  case "$service" in
    monolito-worker) echo "$(zion_docker_config_dir "$service")/docker-compose.worker.yml" ;;
    *)               echo "$(zion_docker_config_dir "$service")/docker-compose.yml" ;;
  esac
}

# Compose de dependencias (versionado)
zion_docker_deps_file() {
  echo "$(zion_docker_config_dir "$1")/docker-compose.deps.yml"
}

# Env file por ambiente (versionado)
zion_docker_env_file() {
  local service="$1" env="$2"
  echo "$(zion_docker_config_dir "$service")/env/${env}.env"
}

zion_docker_project_name() {
  echo "zion-dk-${1}"
}

zion_docker_log_dir() {
  echo "$HOME/.local/share/zion/logs/docker/${1}"
}

# Lista servicos conhecidos
zion_docker_known_services() {
  echo "monolito monolito-worker bo-container front-student"
}

# Valida que o servico existe e tem config
zion_docker_validate_service() {
  local service="$1"
  local dir config_dir compose

  dir=$(zion_docker_service_dir "$service")
  if [[ -z "$dir" ]]; then
    echo "Servico desconhecido: $service" >&2
    echo "Servicos disponiveis: $(zion_docker_known_services)" >&2
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    echo "Diretorio do projeto nao encontrado: $dir" >&2
    echo "Configure ${service^^}_DIR em ~/.zion ou crie o diretorio." >&2
    return 1
  fi

  config_dir=$(zion_docker_config_dir "$service")
  if [[ ! -d "$config_dir" ]]; then
    echo "Config Docker nao encontrada: $config_dir" >&2
    echo "Use a skill /dockerizer para gerar a config." >&2
    return 1
  fi

  compose=$(zion_docker_compose_file "$service")
  if [[ ! -f "$compose" ]]; then
    echo "Compose nao encontrado: $compose" >&2
    return 1
  fi

  return 0
}
