# Registry de servicos Docker conhecidos.
# Paths dos projetos vem de ~/.leech (ex: MONOLITO_DIR=...)
# Configs Docker versionadas em leech/containers/<service>/

# Diretorio do source do projeto (de ~/.leech)
leech_docker_service_dir() {
  local service="$1"
  local var_name
  case "$service" in
    monolito)         var_name="MONOLITO_DIR" ;;
    monolito-worker)  var_name="MONOLITO_DIR" ;;
    bo-container)     var_name="BO_CONTAINER_DIR" ;;
    front-student)    var_name="FRONT_STUDENT_DIR" ;;
    reverseproxy)     echo "${leech_nixos_dir}/leech/docker/reverseproxy"; return 0 ;;
    *) echo ""; return 1 ;;
  esac
  local dir="${!var_name}"
  [[ -z "$dir" ]] && dir="$HOME/projects/estrategia/$service"
  echo "$dir"
}

# Diretorio da config Docker versionada (neste repo)
# monolito-worker aponta pro mesmo dir do monolito
leech_docker_config_dir() {
  local service="$1"
  case "$service" in
    monolito-worker) echo "${leech_nixos_dir}/leech/docker/monolito" ;;
    *)               echo "${leech_nixos_dir}/leech/docker/${service}" ;;
  esac
}

# Compose principal do servico (versionado)
leech_docker_compose_file() {
  local service="$1"
  case "$service" in
    monolito-worker) echo "$(leech_docker_config_dir "$service")/docker-compose.worker.yml" ;;
    *)               echo "$(leech_docker_config_dir "$service")/docker-compose.yml" ;;
  esac
}

# Compose de dependencias (versionado)
leech_docker_deps_file() {
  echo "$(leech_docker_config_dir "$1")/docker-compose.deps.yml"
}

# Env file por ambiente (versionado)
leech_docker_env_file() {
  local service="$1" env="$2"
  echo "$(leech_docker_config_dir "$service")/env/${env}.env"
}

leech_docker_project_name() {
  echo "leech-dk-${1}"
}

leech_docker_log_dir() {
  if [[ "${CLAUDE_ENV:-}" == "container" ]]; then
    echo "/workspace/logs/docker/${1}"
  else
    echo "${XDG_DATA_HOME:-$HOME/.local/share}/leech/logs/dockerized/${1}"
  fi
}

leech_ensure_log_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

# Portas host publicadas por servico (para liberar antes do run)
leech_docker_service_host_ports() {
  case "$1" in
    front-student)   echo "3005" ;;
    bo-container)    echo "9090" ;;
    monolito)        echo "4004 2345 5432 6379 4566" ;;
    monolito-worker) echo "" ;;
    *) echo "" ;;
  esac
}

# Para qualquer container que esteja publicando a porta (fallback apos down)
leech_docker_free_port() {
  local port="$1"
  local ids
  ids=$(docker ps -q --filter "publish=$port" 2>/dev/null)
  if [[ -n "$ids" ]]; then
    echo "[leech docker] Liberando porta $port (parando containers que a usam)..."
    echo "$ids" | xargs -r docker stop 2>/dev/null || true
  fi
}

# Lista servicos conhecidos
leech_docker_known_services() {
  echo "monolito monolito-worker bo-container front-student reverseproxy"
}

# Valida que o servico existe e tem config
leech_docker_validate_service() {
  local service="$1"
  local dir config_dir compose

  dir=$(leech_docker_service_dir "$service")
  if [[ -z "$dir" ]]; then
    echo "Servico desconhecido: $service" >&2
    echo "Servicos disponiveis: $(leech_docker_known_services)" >&2
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    echo "Diretorio do projeto nao encontrado: $dir" >&2
    echo "Configure ${service^^}_DIR em ~/.leech ou crie o diretorio." >&2
    return 1
  fi

  config_dir=$(leech_docker_config_dir "$service")
  if [[ ! -d "$config_dir" ]]; then
    echo "Config Docker nao encontrada: $config_dir" >&2
    echo "Use a skill /dockerizer para gerar a config." >&2
    return 1
  fi

  compose=$(leech_docker_compose_file "$service")
  if [[ ! -f "$compose" ]]; then
    echo "Compose nao encontrado: $compose" >&2
    return 1
  fi

  return 0
}

# --- Worktree support ---

_LEECH_DK_WORKTREE=""
_LEECH_DK_WORKTREE_DIR=""

# Resolve um worktree por nome (ultimo componente do path).
# Seta _LEECH_DK_WORKTREE e _LEECH_DK_WORKTREE_DIR.
leech_docker_init_worktree() {
  local service="$1" worktree="${2:-}"
  _LEECH_DK_WORKTREE=""
  _LEECH_DK_WORKTREE_DIR=""
  [[ -z "$worktree" ]] && return 0

  local base_dir
  base_dir=$(leech_docker_service_dir "$service")
  [[ ! -d "$base_dir" ]] && { echo "Diretorio base nao encontrado: $base_dir" >&2; return 1; }

  local wt_path=""
  while IFS= read -r line; do
    local p="${line%% *}"
    local name
    name=$(basename "$p")
    if [[ "$name" == "$worktree" ]]; then
      wt_path="$p"
      break
    fi
  done < <(git -C "$base_dir" worktree list 2>/dev/null)

  if [[ -z "$wt_path" ]]; then
    echo "Worktree '$worktree' nao encontrado para $service." >&2
    echo "Disponiveis:" >&2
    git -C "$base_dir" worktree list 2>/dev/null | sed 's/^/  /' >&2
    return 1
  fi

  # Validar que o path tem arquivos do projeto.
  # Worktrees criados dentro do container gravam paths como /workspace/mnt/...
  # que no host sao diretorios vazios. Nesse caso, reconstruir o path relativo
  # a partir do base_dir do host.
  if [[ ! -f "$wt_path/package.json" && ! -f "$wt_path/go.mod" ]]; then
    # Tentar: base_dir + caminho relativo do worktree (ex: .claude/worktrees/<name>)
    local git_toplevel
    git_toplevel=$(git -C "$base_dir" rev-parse --show-toplevel 2>/dev/null)

    # Extrair path relativo: se git reportou /workspace/mnt/X/.claude/worktrees/Y
    # e o toplevel no container era /workspace/mnt/X, o relativo eh .claude/worktrees/Y
    local rel_path=""
    # Tentar todas as possiveis raizes de container (/workspace/mnt, /workspace/nixos)
    for container_root in "/workspace/mnt" "/workspace/nixos" "/workspace"; do
      if [[ "$wt_path" == "$container_root/"* ]]; then
        # wt_path relativo ao projeto dentro do container
        local container_project_path
        container_project_path=$(echo "$wt_path" | sed "s|^$container_root/||")
        # Reconstruir: pegar so a parte apos o nome do servico (ou base dir)
        local base_name
        base_name=$(basename "$base_dir")
        if [[ "$container_project_path" == *"$base_name/"* ]]; then
          rel_path="${container_project_path#*$base_name/}"
        fi
        break
      fi
    done

    # Fallback: tentar path padrao do Claude Code
    if [[ -z "$rel_path" ]]; then
      rel_path=".claude/worktrees/$worktree"
    fi

    local alt_path="$base_dir/$rel_path"
    if [[ -f "$alt_path/package.json" || -f "$alt_path/go.mod" ]]; then
      echo "[leech docker] Path corrigido: $alt_path" >&2
      echo "  (git reportou path de container: $wt_path)" >&2
      wt_path="$alt_path"
    else
      echo "Worktree '$worktree' encontrado mas sem arquivos do projeto." >&2
      echo "  git reportou: $wt_path" >&2
      echo "  tentativa:    $alt_path" >&2
      echo "O worktree pode ter sido criado dentro de um container com path diferente." >&2
      return 1
    fi
  fi

  _LEECH_DK_WORKTREE="$worktree"
  _LEECH_DK_WORKTREE_DIR="$wt_path"
}

# Dir efetivo (worktree se setado, senao service dir)
leech_docker_effective_dir() {
  local service="$1"
  if [[ -n "$_LEECH_DK_WORKTREE_DIR" ]]; then
    echo "$_LEECH_DK_WORKTREE_DIR"
  else
    leech_docker_service_dir "$service"
  fi
}

# Project name efetivo (inclui sufixo -wt-<nome> se worktree)
leech_docker_effective_project() {
  local service="$1"
  if [[ -n "$_LEECH_DK_WORKTREE" ]]; then
    local safe
    safe=$(echo "$_LEECH_DK_WORKTREE" | tr '/' '-' | tr '[:upper:]' '[:lower:]')
    echo "leech-dk-${service}-wt-${safe}"
  else
    leech_docker_project_name "$service"
  fi
}

# Exporta *_DIR overridado para compose
leech_docker_export_dirs() {
  local service="$1"
  export MONOLITO_DIR="${MONOLITO_DIR:-$HOME/projects/estrategia/monolito}"
  export BO_CONTAINER_DIR="${BO_CONTAINER_DIR:-$HOME/projects/estrategia/bo-container}"
  export FRONT_STUDENT_DIR="${FRONT_STUDENT_DIR:-$HOME/projects/estrategia/front-student}"

  if [[ -n "$_LEECH_DK_WORKTREE_DIR" ]]; then
    case "$service" in
      monolito|monolito-worker) export MONOLITO_DIR="$_LEECH_DK_WORKTREE_DIR" ;;
      bo-container)             export BO_CONTAINER_DIR="$_LEECH_DK_WORKTREE_DIR" ;;
      front-student)            export FRONT_STUDENT_DIR="$_LEECH_DK_WORKTREE_DIR" ;;
    esac
  fi
}

# Lista worktrees de um servico (formato: path branch)
leech_docker_list_worktrees() {
  local service="$1"
  local dir
  dir=$(leech_docker_service_dir "$service")
  [[ ! -d "$dir" ]] && return 1
  git -C "$dir" worktree list 2>/dev/null
}

# Lista worktrees de todos os servicos
leech_docker_list_all_worktrees() {
  local services="monolito bo-container front-student"
  for svc in $services; do
    local dir
    dir=$(leech_docker_service_dir "$svc")
    [[ ! -d "$dir" ]] && continue
    local wt_count
    wt_count=$(git -C "$dir" worktree list 2>/dev/null | wc -l)
    [[ "$wt_count" -le 1 ]] && continue
    echo "SERVICE:$svc"
    git -C "$dir" worktree list 2>/dev/null
    echo ""
  done
}

# --- Reverse Proxy (sobe/desce automaticamente com servicos estrategia) ---

_REVERSEPROXY_DIR="${leech_nixos_dir}/leech/docker/reverseproxy"
_REVERSEPROXY_PROJECT="leech-dk-reverseproxy"

# Sobe o reverse proxy se ainda nao estiver rodando.
# Gera certs autoassinados se nao existirem.
leech_docker_ensure_reverseproxy() {
  # Ja esta rodando?
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^leech-reverseproxy$'; then
    return 0
  fi

  # Gerar certs se nao existem
  if [[ ! -f "$_REVERSEPROXY_DIR/certs/fullchain.pem" ]]; then
    echo "[leech docker] Gerando certificados do reverse proxy..."
    bash "$_REVERSEPROXY_DIR/gen-cert.sh"
  fi

  echo "[leech docker] Subindo reverse proxy (80/443 -> 4004)..."
  docker compose -f "$_REVERSEPROXY_DIR/docker-compose.yml" -p "$_REVERSEPROXY_PROJECT" up -d --remove-orphans 2>/dev/null
}

# Desce o reverse proxy se nenhum servico estrategia estiver rodando.
leech_docker_stop_reverseproxy_if_idle() {
  local services
  services=$(leech_docker_known_services)
  for svc in $services; do
    local proj
    proj=$(leech_docker_project_name "$svc")
    if docker compose -p "$proj" ps --status running -q 2>/dev/null | grep -q .; then
      return 0  # ainda tem servico rodando, manter proxy
    fi
  done

  # Nenhum servico rodando — derrubar proxy
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^leech-reverseproxy$'; then
    echo "[leech docker] Nenhum servico estrategia rodando, parando reverse proxy..."
    docker compose -f "$_REVERSEPROXY_DIR/docker-compose.yml" -p "$_REVERSEPROXY_PROJECT" down 2>/dev/null
  fi
}

# --- Container → Host path translation ---
# Quando o agente roda dentro do container, os *_DIR apontam para /home/claude/projects/...
# Mas o Docker daemon (no host) precisa de paths do host para volumes e build context.
# Os mirror mounts (${HOME}/projects:${HOME}/projects no compose) garantem que host paths
# existem fisicamente dentro do container, entao apos fixup tudo funciona:
# - docker compose build (CLI le context localmente via mirror mount)
# - docker compose up (daemon resolve volumes no host)
# - docker run -v (daemon resolve no host)
_leech_dk_container_fixup() {
  [[ "${CLAUDE_ENV:-}" != "container" ]] && return 0
  local host_home="${HOST_HOME:-}"
  [[ -z "$host_home" ]] && return 0

  local container_home="/home/claude"

  # Traduzir *_DIR de /home/claude/... para host paths
  for var in MONOLITO_DIR BO_CONTAINER_DIR FRONT_STUDENT_DIR; do
    local val="${!var:-}"
    [[ -n "$val" ]] && export "$var"="${val/#$container_home/$host_home}"
  done

  # Traduzir SSH path para docker run (install/shell)
  export HOST_SSH_DIR="${host_home}/.ssh"
  export HOST_NPMRC="${host_home}/.npmrc"

  # LEECH_NIXOS_DIR para compose files que referenciam paths do host
  export LEECH_NIXOS_DIR="${HOST_NIXOS_DIR:-$host_home/nixos}"
  # Atualizar shell var tambem (usada por leech_docker_config_dir apos fixup)
  leech_nixos_dir="$LEECH_NIXOS_DIR"
}
