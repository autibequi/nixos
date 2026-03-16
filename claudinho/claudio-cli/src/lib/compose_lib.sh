# Shared helpers for claudio CLI (compose file, mount path, project names).
# Sourced by generated script. Uses CLAUDIO_NIXOS_DIR, OBSIDIAN_PATH, args, flag_*.
# Toda a lógica de container vive em claudio-cli; compose e Dockerfile ficam aqui.

claudio_nixos_dir="${CLAUDIO_NIXOS_DIR:-$HOME/nixos}"
claudio_cli_dir="$claudio_nixos_dir/claudinho/claudio-cli"
claudio_compose_file="$claudio_cli_dir/docker-compose.claude.yml"
claudio_compose_dir="$claudio_cli_dir"
# Config do usuário: engine padrão e chaves (GH_TOKEN, ANTHROPIC_API_KEY)
claudio_config_file="${CLAUDIO_CONFIG:-$HOME/.claudio}"
claudio_env_file="$claudio_cli_dir/.env"
claudio_obsidian_path="${OBSIDIAN_PATH:-$HOME/.ovault}"

# Carrega ~/.claudio (KEY=value, sourceável) e exporta para o compose/container.
# Flags --engine e --model na linha de comando sempre sobrescrevem estes valores.
claudio_load_config() {
  if [[ -f "$claudio_config_file" ]]; then
    # shellcheck source=/dev/null
    source "$claudio_config_file"
    [[ -n "${engine:-}" ]] && export CLAUDIO_ENGINE="$engine"
    [[ -n "${model:-}" ]] && export CLAUDIO_MODEL="$model"
    [[ -n "${GH_TOKEN:-}" ]] && export GH_TOKEN
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] && export ANTHROPIC_API_KEY
    [[ -n "${OBSIDIAN_PATH:-}" ]] && export OBSIDIAN_PATH && claudio_obsidian_path="$OBSIDIAN_PATH"
  fi
}

# Engine: opencode | claude | cursor. Se required=1 e vazio, reclama e sai.
# Ordem: --engine= na linha de comando sobrescreve ~/.claudio (CLAUDIO_ENGINE).
claudio_resolve_engine() {
  local required="${1:-0}"
  local e="${args['--engine']:-${flag_engine:-$CLAUDIO_ENGINE}}"  # flag > config
  e="${e,,}"
  if [[ -z "$e" ]]; then
    if [[ "$required" == "1" ]]; then
      echo "claudio: --engine=opencode|claude|cursor é obrigatório (ou defina engine= em ~/.claudio)" >&2
      exit 1
    fi
    return 0
  fi
  case "$e" in
    opencode|claude|cursor) echo "$e" ;;
    *)
      echo "claudio: engine inválido: $e (use opencode, claude ou cursor)" >&2
      exit 1
      ;;
  esac
}
# Paths usados pelos comandos worker/logs/status/new/reset (equiv. makefile)
claudio_nixos_logs="$claudio_nixos_dir/logs"
claudio_nixos_scripts="$claudio_nixos_dir/scripts"
claudio_vault_dir="${claudio_vault_dir:-$claudio_nixos_dir/vault}"
claudio_ephemeral="$claudio_nixos_dir/.ephemeral"

# Compose + env para invocar docker/podman (executar com cwd = claudio_compose_dir ou -f)
claudio_compose_cmd() {
  local cmd=(docker compose -f "$claudio_compose_file")
  [[ -f "$claudio_env_file" ]] && cmd+=(--env-file "$claudio_env_file")
  "${cmd[@]}" "$@"
}

# Resolve mount directory: named arg "dir" (bashly uses args['dir']) or default ~/projects
claudio_resolve_dir() {
  local dir="${args[dir]:-$HOME/projects}"
  if [[ -n "$dir" ]]; then
    (cd "$dir" 2>/dev/null && pwd) || { echo "claudio: dir not found: $dir" >&2; exit 1; }
  else
    echo "$HOME/projects"
  fi
}

# Slug from dir basename (lowercase, alphanumeric + hyphen)
claudio_proj_slug() {
  local d="$1"
  basename "$d" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//'
}

# Project name for claude (clau-SLUG or clau-SLUG-INSTANCE)
claudio_proj_name() {
  local slug="$1"
  local instance="${args['--instance']:-${flag_instance:-}}"
  local name="clau-${slug}"
  [[ -n "$instance" && "$instance" != "1" ]] && name="${name}-${instance}"
  echo "$name"
}

# Project name for opencode (persistent sandbox)
claudio_proj_name_open() {
  local slug="$1"
  echo "clau-${slug}-open"
}

# Mount opts: --rw (default for run) or --ro
claudio_mount_opts() {
  if [[ -n "${args['--rw']:-${flag_rw:-}}" ]]; then echo "rw"; elif [[ -n "${args['--ro']:-${flag_ro:-}}" ]]; then echo "ro"; else echo "rw"; fi
}

# Model flag for claude binary (--model=haiku|opus; default = nada = sonnet).
# Ordem: --model= na linha de comando sobrescreve ~/.claudio (CLAUDIO_MODEL).
claudio_model_flag() {
  local m="${args['--model']:-${flag_model:-$CLAUDIO_MODEL}}"  # flag > config
  m="${m,,}"
  case "$m" in
    haiku) echo "--model claude-haiku-4-5-20251001" ;;
    opus)  echo "--model claude-opus-4-6" ;;
    *)     echo "" ;;
  esac
}
