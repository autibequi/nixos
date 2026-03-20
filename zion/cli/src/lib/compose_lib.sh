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
zion_obsidian_path="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"

# Garante HOME para o compose expandir ${HOME}/nixos e paths; usado por todos os comandos que montam volumes.
# Garante HOME correto (corrige warning do Nix quando HOME nao bate com passwd)
export HOME="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6 || eval echo ~"$(id -un)")"

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
    [[ -n "${GRAFANA_URL:-}" ]] && export GRAFANA_URL
    [[ -n "${GRAFANA_TOKEN:-}" ]] && export GRAFANA_TOKEN
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
  # Journal GID para group_add no compose (agente precisa ler /var/log/journal)
  if [[ -z "${JOURNAL_GID:-}" ]]; then
    JOURNAL_GID=$(getent group systemd-journal 2>/dev/null | cut -d: -f3)
  fi
  export JOURNAL_GID="${JOURNAL_GID:-62}"
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

# ── Compose env helper ──────────────────────────────────────────────────────
# Exporta as variáveis necessárias para o compose expandir volumes.
# Chamado internamente por zion_session_run; pode ser usado diretamente.
zion_compose_env() {
  export HOME="${HOME:-$(eval echo ~"$(id -un)")}"
  export CLAUDIO_MOUNT="$1"
  export CLAUDIO_MOUNT_OPTS="$2"
  export OBSIDIAN_PATH="$zion_obsidian_path"
}

# ── Unified session runner ──────────────────────────────────────────────────
# Centraliza o dispatch de engine (opencode/claude/cursor) para todas as sessões.
#
# Uso:
#   zion_session_run <engine> <proj_name> <mount_path> <mount_opts> <mode> [engine_args] [extra_volumes]
#
# Parâmetros:
#   engine        - opencode | claude | cursor
#   proj_name     - nome do projeto compose (ex: zion-projects)
#   mount_path    - path absoluto do projeto no host
#   mount_opts    - rw | ro
#   mode          - engine_args string com flags específicas do engine:
#                     --continue, --resume, --resume=UUID, --init-md=file
#                   Flags reconhecidas e mapeadas por engine automaticamente.
#   extra_volumes - string com volumes extras (ex: "-v /var/log/journal:/workspace/logs/host/journal:ro")
#
# O mode "persistent" (up -d + exec) é usado quando opencode precisa de leech persistente.
# Demais engines usam "run --rm -it" (efêmero).
zion_session_run() {
  local engine="$1"
  local proj_name="$2"
  local mount_path="$3"
  local mount_opts="$4"
  local engine_args="${5:-}"
  local extra_volumes="${6:-}"
  # Analysis mode: passa ZION_ANALYSIS_MODE=1 pro container via env
  local analysis_env=""
  [[ -n "${flag_analysis_mode:-${args['--analysis-mode']:-}}" ]] && analysis_env="-e ZION_ANALYSIS_MODE=1"

  zion_compose_env "$mount_path" "$mount_opts"

  local danger model

  case "$engine" in
    opencode)
      # Opencode usa up -d + exec (persistent sandbox)
      local oc_envs=()
      oc_envs+=(-e "CLAUDIO_MOUNT=$mount_path")
      oc_envs+=(-e "BOOTSTRAP_SKIP_CLEAR=1")

      # Model
      local _oc_model
      _oc_model="$(zion_model_id opencode)"
      [[ -n "$_oc_model" ]] && oc_envs+=(-e "OPENCODE_MODEL=$_oc_model")

      # Danger
      [[ -n "${flag_danger:-${args['--danger']:-${ZION_DANGER:-}}}" ]] && oc_envs+=(-e "OPENCODE_PERMISSION_BYPASS=1")

      # Init-md
      if [[ "$engine_args" == *"--init-md="* ]]; then
        local init_file="${engine_args#*--init-md=}"
        init_file="${init_file%% *}"
        [[ -n "$init_file" ]] && oc_envs+=(-e "CLAUDE_INITIAL_MD=/workspace/mnt/$init_file")
      fi

      # Resume
      if [[ "$engine_args" == *"--resume="* ]]; then
        local resume_id="${engine_args#*--resume=}"
        resume_id="${resume_id%% *}"
        [[ -n "$resume_id" ]] && oc_envs+=(-e "CLAUDIO_RESUME_SESSION=$resume_id")
      fi

      # Opencode: persistent (up + exec) for new; ephemeral (run) for continue/resume
      if [[ "$engine_args" == *"--continue"* ]] || [[ "$engine_args" == *"--resume"* ]]; then
        zion_compose_cmd -p "$proj_name" run --rm -it $extra_volumes $analysis_env \
          --entrypoint /entrypoint.sh "${oc_envs[@]}" leech \
          /bin/bash -c 'cd /workspace/mnt && opencode'
      else
        zion_compose_cmd -p "$proj_name" up -d leech
        zion_compose_cmd -p "$proj_name" exec -it -u claude \
          $analysis_env "${oc_envs[@]}" leech bash -c 'cd /workspace/mnt && exec opencode'
      fi
      ;;

    claude)
      model="$(zion_model_flag claude)"
      danger="$(zion_danger_flag claude)"

      # Build claude CLI args
      local claude_args="${model}${danger}"

      # Continue
      [[ "$engine_args" == *"--continue"* ]] && claude_args+=" --continue"

      # Resume
      if [[ "$engine_args" == *"--resume="* ]]; then
        local resume_id="${engine_args#*--resume=}"
        resume_id="${resume_id%% *}"
        if [[ "$resume_id" == "1" ]]; then
          claude_args+=" --resume"
        else
          claude_args+=" --resume=$resume_id"
        fi
      elif [[ "$engine_args" == *"--resume"* ]]; then
        claude_args+=" --resume"
      fi

      # Init-md
      if [[ "$engine_args" == *"--init-md="* ]]; then
        local init_file="${engine_args#*--init-md=}"
        init_file="${init_file%% *}"
        [[ -n "$init_file" ]] && claude_args+=" --append-system-prompt-file $init_file"
      fi

      # Always bypass permissions (was hardcoded in continue and resume)
      [[ "$claude_args" != *"--permission-mode"* ]] && claude_args+=" --permission-mode bypassPermissions"

      # Session name = mounted folder (shown in header and statusline)
      [[ -n "$mount_path" ]] && claude_args+=" --name ${mount_path##*/}"

      zion_compose_cmd -p "$proj_name" run --rm -it $extra_volumes $analysis_env \
        --entrypoint /entrypoint.sh -e "CLAUDIO_MOUNT=$mount_path" -e "BOOTSTRAP_SKIP_CLEAR=1" leech \
        /bin/bash -c ". /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude ${claude_args}"
      ;;

    cursor)
      danger="$(zion_danger_flag cursor)"
      model="$(zion_model_flag cursor)"
      local name_flag=""
      [[ -n "$mount_path" ]] && name_flag=" --name ${mount_path##*/}"
      local agent_flags="${danger}${model:+ $model}${name_flag}"

      local cursor_envs=()
      cursor_envs+=(-e "CLAUDIO_MOUNT=$mount_path")
      cursor_envs+=(-e "BOOTSTRAP_SKIP_CLEAR=1")

      local cursor_cmd='. /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt; '

      # Resume (takes priority over init-md)
      if [[ "$engine_args" == *"--resume="* ]]; then
        local resume_id="${engine_args#*--resume=}"
        resume_id="${resume_id%% *}"
        cursor_envs+=(-e "CLAUDIO_RESUME_SESSION=$resume_id")
        cursor_cmd+='exec agent'"${agent_flags}"' --resume="${CLAUDIO_RESUME_SESSION}"'
      elif [[ "$engine_args" == *"--continue"* ]]; then
        cursor_cmd+='exec agent'"${agent_flags}"' --continue'
      elif [[ "$engine_args" == *"--init-md="* ]]; then
        local init_file="${engine_args#*--init-md=}"
        init_file="${init_file%% *}"
        cursor_envs+=(-e "CLAUDIO_INITIAL_MD=$init_file")
        cursor_cmd+='if [ -n "${CLAUDIO_INITIAL_MD:-}" ] && [ -f "/workspace/mnt/$CLAUDIO_INITIAL_MD" ]; then '
        cursor_cmd+='p=$(sed -e '\''s/\\\\/\\\\\\\\/g'\'' -e '\''s/"/\\"/g'\'' "/workspace/mnt/$CLAUDIO_INITIAL_MD"); exec agent'"${agent_flags}"' "$p"; '
        cursor_cmd+='else exec agent'"${agent_flags}"'; fi'
      else
        cursor_cmd+='exec agent'"${agent_flags}"
      fi

      zion_compose_cmd -p "$proj_name" run --rm -it $extra_volumes $analysis_env \
        --entrypoint /entrypoint.sh "${cursor_envs[@]}" leech \
        /bin/bash -c "$cursor_cmd"
      ;;

    *)
      echo "zion: engine inválido: $engine (use opencode|claude|cursor)" >&2
      exit 1
      ;;
  esac
}
