# Shared helpers for zion CLI (compose file, mount path, project names).
# Sourced by generated script. Uses ZION_NIXOS_DIR, OBSIDIAN_PATH, args, flag_*.
# Toda a lógica de container vive em cli; compose e Dockerfile ficam aqui.

zion_nixos_dir="${ZION_NIXOS_DIR:-$HOME/nixos}"
zion_cli_dir="$zion_nixos_dir/zion/cli"
zion_compose_file="$zion_cli_dir/docker-compose.zion.yml"
zion_compose_dir="$zion_cli_dir"
# Config do usuário: engine padrão e chaves (GH_TOKEN, ANTHROPIC_API_KEY)
zion_config_file="${ZION_CONFIG:-$HOME/.zion}"
zion_env_file="$zion_cli_dir/.env"
zion_obsidian_path="${OBSIDIAN_PATH:-$HOME/.ovault}"

# Garante HOME para o compose expandir ${HOME}/nixos e paths; usado por todos os comandos que montam volumes.
[[ -z "${HOME:-}" ]] && export HOME="$(eval echo ~"$(id -un)")"

# Carrega ~/.zion (KEY=value, sourceável) e exporta para o compose/container.
# Flags --engine e --model na linha de comando sempre sobrescrevem estes valores.
zion_load_config() {
  if [[ -f "$zion_config_file" ]]; then
    # shellcheck source=/dev/null
    source "$zion_config_file"
    [[ -n "${engine:-}" ]] && export ZION_ENGINE="$engine"
    [[ -n "${model:-}" ]] && export ZION_MODEL="$model"
    # Modelos por engine (model_claude=, model_opencode=, model_cursor=)
    [[ -n "${model_claude:-}" ]]   && export ZION_MODEL_CLAUDE="$model_claude"
    [[ -n "${model_opencode:-}" ]] && export ZION_MODEL_OPENCODE="$model_opencode"
    [[ -n "${model_cursor:-}" ]]   && export ZION_MODEL_CURSOR="$model_cursor"
    if [[ -n "${DANGER:-${danger:-}}" ]] && [[ "${DANGER:-${danger:-}}" != "0" ]] && [[ "${DANGER:-${danger:-}}" != "false" ]]; then
      export ZION_DANGER=1
    fi
    [[ -n "${GH_TOKEN:-}" ]] && export GH_TOKEN
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] && export ANTHROPIC_API_KEY
    [[ -n "${CURSOR_API_KEY:-}" ]] && export CURSOR_API_KEY
    if [[ -n "${OBSIDIAN_PATH:-}" ]]; then
      export OBSIDIAN_PATH
      zion_obsidian_path="$OBSIDIAN_PATH"
    fi
  fi
  # Docker GID para group_add no compose (agente precisa acessar /var/run/docker.sock)
  if [[ -z "${DOCKER_GID:-}" ]] && [[ -S /var/run/docker.sock ]]; then
    DOCKER_GID=$(stat -c %g /var/run/docker.sock)
  fi
  export DOCKER_GID="${DOCKER_GID:-999}"
  # Path absoluto e ~ expandido para o compose (YAML não expande ~)
  zion_obsidian_path="${zion_obsidian_path/#\~/$HOME}"
  [[ -d "$zion_obsidian_path" ]] && zion_obsidian_path="$(cd "$zion_obsidian_path" && pwd)"
  export OBSIDIAN_PATH="$zion_obsidian_path"
}

# Engine: opencode | claude | cursor. Se required=1 e vazio, reclama e sai.
# Ordem: --engine= na linha de comando sobrescreve ~/.zion (ZION_ENGINE).
zion_resolve_engine() {
  local required="${1:-0}"
  local e="${args['--engine']:-${flag_engine:-$ZION_ENGINE}}"  # flag > config
  e="${e,,}"
  if [[ -z "$e" ]]; then
    if [[ "$required" == "1" ]]; then
      echo "zion: --engine=opencode|claude|cursor é obrigatório (ou defina engine= em ~/.zion)" >&2
      exit 1
    fi
    return 0
  fi
  case "$e" in
    opencode|claude|cursor) echo "$e" ;;
    *)
      echo "zion: engine inválido: $e (use opencode, claude ou cursor)" >&2
      exit 1
      ;;
  esac
}
# Paths usados pelos comandos worker/logs/status/new/reset (equiv. makefile)
zion_nixos_logs="$zion_nixos_dir/logs"
zion_nixos_scripts="$zion_nixos_dir/scripts"
zion_vault_dir="${zion_vault_dir:-$zion_nixos_dir/vault}"
zion_ephemeral="$zion_nixos_dir/.ephemeral"

# Compose + env para invocar docker/podman (executar com cwd = zion_compose_dir ou -f)
zion_compose_cmd() {
  local cmd=(docker compose -f "$zion_compose_file")
  [[ -f "$zion_env_file" ]] && cmd+=(--env-file "$zion_env_file")
  "${cmd[@]}" "$@"
}

# Resolve mount directory: named arg "dir" (bashly uses args['dir']) or default ~/projects
zion_resolve_dir() {
  local dir="${args[dir]:-$HOME/projects}"
  if [[ -n "$dir" ]]; then
    (cd "$dir" 2>/dev/null && pwd) || { echo "zion: dir not found: $dir" >&2; exit 1; }
  else
    echo "$HOME/projects"
  fi
}

# Slug from dir basename (lowercase, alphanumeric + hyphen)
zion_proj_slug() {
  local d="$1"
  basename "$d" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//'
}

# Project name for agent sessions (Zion)
zion_proj_name() {
  local slug="$1"
  local instance="${args['--instance']:-${flag_instance:-}}"
  local name="zion-${slug}"
  [[ -n "$instance" && "$instance" != "1" ]] && name="${name}-${instance}"
  echo "$name"
}

# Project name for opencode (persistent sandbox)
zion_proj_name_open() {
  local slug="$1"
  echo "zion-${slug}-open"
}

# Mount opts: --rw (default for run) or --ro
zion_mount_opts() {
  if [[ -n "${args['--rw']:-${flag_rw:-}}" ]]; then echo "rw"; elif [[ -n "${args['--ro']:-${flag_ro:-}}" ]]; then echo "ro"; else echo "rw"; fi
}

# --init-md: path do markdown inicial (relativo ao mount); vazio se arquivo não existe
# Valor vem de flag_init_md (run seta de args) ou ZION_INITIAL_MD. Default contexto.md é no bashly (--init-md sem arg).
zion_initial_md() {
  local mount="${1:-}"
  local f="${flag_init_md:-${ZION_INITIAL_MD:-}}"
  [[ -z "$f" ]] && return 0
  local full="$mount/$f"
  [[ -f "$full" ]] && echo "$f" || echo ""
}

# --danger: sufixo/args de bypass de permissões por engine (vazio se flag não setada).
# Config ~/.zion: DANGER=true deixa danger sempre ligado.
zion_danger_flag() {
  if [[ -z "${flag_danger:-${args['--danger']:-${ZION_DANGER:-}}}" ]]; then
    echo ""
    return 0
  fi
  case "${1:-}" in
    claude)  echo " --permission-mode bypassPermissions" ;;
    cursor)  echo " --force" ;;
    opencode) echo "" ;;
    *) echo "" ;;
  esac
}

# Converte shorthand de modelo para o ID completo (uso interno).
zion_resolve_model_id() {
  local m="${1,,}"
  case "$m" in
    haiku)   echo "claude-haiku-4-5-20251001" ;;
    opus)    echo "claude-opus-4-6" ;;
    sonnet)  echo "claude-sonnet-4-6" ;;
    "")      echo "" ;;
    *)       echo "$m" ;;  # já é ID completo
  esac
}

# Model flag para binários que aceitam --model=<id> (claude, cursor/agent).
# Aceita engine como argumento opcional para usar o modelo por engine.
# Ordem: --model= (CLI) > model_<engine>= (~/.zion) > model= (~/.zion).
zion_model_flag() {
  local engine="${1:-}"
  local cli_flag="${args['--model']:-${flag_model:-}}"
  local per_engine=""
  case "${engine,,}" in
    claude)   per_engine="${ZION_MODEL_CLAUDE:-}" ;;
    opencode) per_engine="${ZION_MODEL_OPENCODE:-}" ;;
    cursor)   per_engine="${ZION_MODEL_CURSOR:-}" ;;
  esac
  local m="${cli_flag:-${per_engine:-$ZION_MODEL}}"
  local id
  id="$(zion_resolve_model_id "$m")"
  [[ -n "$id" ]] && echo "--model $id" || echo ""
}

# Resolve model ID bruto (sem flag prefix) para engines como opencode que usam env var.
# Ordem: --model= (CLI) > model_opencode= (~/.zion) > model= (~/.zion).
zion_model_id() {
  local engine="${1:-}"
  local cli_flag="${args['--model']:-${flag_model:-}}"
  local per_engine=""
  case "${engine,,}" in
    claude)   per_engine="${ZION_MODEL_CLAUDE:-}" ;;
    opencode) per_engine="${ZION_MODEL_OPENCODE:-}" ;;
    cursor)   per_engine="${ZION_MODEL_CURSOR:-}" ;;
  esac
  local m="${cli_flag:-${per_engine:-$ZION_MODEL}}"
  zion_resolve_model_id "$m"
}
