# Shared helpers for leech CLI (compose file, mount path, project names).
# Sourced by generated script. Uses LEECH_NIXOS_DIR, OBSIDIAN_PATH, args, flag_*.
# Toda a lógica de container vive em container/; scripts CLI vivem em clibash/.

# Garante HOME correto ANTES de qualquer path ser definido.
# Nix pode sobrescrever HOME para /root quando HOME nao pertence ao usuario atual.
# Fallback para HOME original se getent e tilde expansion falharem (comum no NixOS).
_leech_resolved_home="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6 || eval echo ~"$(id -un)" 2>/dev/null)"
export HOME="${_leech_resolved_home:-$HOME}"
unset _leech_resolved_home

leech_nixos_dir="${LEECH_NIXOS_DIR:-$HOME/nixos}"
leech_bash_dir="$leech_nixos_dir/leech/bash"
leech_container_dir="$leech_nixos_dir/leech/docker/leech"
leech_compose_file="$leech_container_dir/docker-compose.leech.yml"
leech_compose_dir="$leech_container_dir"
# Config do usuário: engine padrão e chaves (GH_TOKEN, ANTHROPIC_API_KEY)
leech_config_file="${LEECH_CONFIG:-$HOME/.leech}"
leech_env_file="$leech_container_dir/.env"
leech_obsidian_path="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"

# Carrega ~/.leech (KEY=value, sourceável) e exporta para o compose/container.
# Flags --engine e --model na linha de comando sempre sobrescrevem estes valores.
leech_load_config() {
  if [[ -f "$leech_config_file" ]]; then
    # shellcheck source=/dev/null
    source "$leech_config_file"
    [[ -n "${engine:-}" ]] && export LEECH_ENGINE="$engine"
    [[ -n "${model:-}" ]] && export LEECH_MODEL="$model"
    # Modelos por engine (model_claude=, model_opencode=, model_cursor=)
    [[ -n "${model_claude:-}" ]]   && export LEECH_MODEL_CLAUDE="$model_claude"
    [[ -n "${model_opencode:-}" ]] && export LEECH_MODEL_OPENCODE="$model_opencode"
    [[ -n "${model_cursor:-}" ]]   && export LEECH_MODEL_CURSOR="$model_cursor"
    if [[ -n "${DANGER:-${danger:-}}" ]] && [[ "${DANGER:-${danger:-}}" != "0" ]] && [[ "${DANGER:-${danger:-}}" != "false" ]]; then
      export LEECH_DANGER=1
    fi
    [[ -n "${GH_TOKEN:-}" ]] && export GH_TOKEN
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] && export ANTHROPIC_API_KEY
    [[ -n "${CURSOR_API_KEY:-}" ]] && export CURSOR_API_KEY
    [[ -n "${GRAFANA_URL:-}" ]] && export GRAFANA_URL
    [[ -n "${GRAFANA_TOKEN:-}" ]] && export GRAFANA_TOKEN
    if [[ -n "${OBSIDIAN_PATH:-}" ]]; then
      export OBSIDIAN_PATH
      leech_obsidian_path="$OBSIDIAN_PATH"
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
  leech_obsidian_path="${leech_obsidian_path/#\~/$HOME}"
  [[ -d "$leech_obsidian_path" ]] && leech_obsidian_path="$(cd "$leech_obsidian_path" && pwd)"
  export OBSIDIAN_PATH="$leech_obsidian_path"
}

# Engine: opencode | claude | cursor. Se required=1 e vazio, reclama e sai.
# Ordem: --engine= na linha de comando sobrescreve ~/.leech (LEECH_ENGINE).
leech_resolve_engine() {
  local required="${1:-0}"
  local e="${args['--engine']:-${flag_engine:-$LEECH_ENGINE}}"  # flag > config
  e="${e,,}"
  if [[ -z "$e" ]]; then
    if [[ "$required" == "1" ]]; then
      echo "leech: --engine=opencode|claude|cursor é obrigatório (ou defina engine= em ~/.leech)" >&2
      exit 1
    fi
    return 0
  fi
  case "$e" in
    opencode|claude|cursor) echo "$e" ;;
    *)
      echo "leech: engine inválido: $e (use opencode, claude ou cursor)" >&2
      exit 1
      ;;
  esac
}
# Paths usados pelos comandos worker/logs/status/new/reset (equiv. makefile)
leech_nixos_logs="$leech_nixos_dir/logs"
leech_nixos_scripts="$leech_nixos_dir/scripts"
leech_vault_dir="${leech_vault_dir:-$leech_nixos_dir/vault}"
leech_ephemeral="$leech_nixos_dir/.ephemeral"

# Compose + env para invocar docker/podman (executar com cwd = leech_compose_dir ou -f)
leech_compose_cmd() {
  local cmd=(docker compose -f "$leech_compose_file")
  [[ -f "$leech_env_file" ]] && cmd+=(--env-file "$leech_env_file")
  "${cmd[@]}" "$@"
}

# Resolve mount directory: named arg "dir" (bashly uses args['dir']) or default ~/projects
leech_resolve_dir() {
  local dir="${args[dir]:-$HOME/projects}"
  if [[ -n "$dir" ]]; then
    (cd "$dir" 2>/dev/null && pwd) || { echo "leech: dir not found: $dir" >&2; exit 1; }
  else
    echo "$HOME/projects"
  fi
}

# Slug from dir basename (lowercase, alphanumeric + hyphen)
leech_proj_slug() {
  local d="$1"
  basename "$d" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//'
}

# Project name for agent sessions (Leech)
leech_proj_name() {
  local slug="$1"
  local instance="${args['--instance']:-${flag_instance:-}}"
  local name="leech-${slug}"
  [[ -n "$instance" && "$instance" != "1" ]] && name="${name}-${instance}"
  echo "$name"
}

# Project name for opencode (persistent sandbox)
leech_proj_name_open() {
  local slug="$1"
  echo "leech-${slug}-open"
}

# Mount opts: --rw (default for run) or --ro
leech_mount_opts() {
  if [[ -n "${args['--rw']:-${flag_rw:-}}" ]]; then echo "rw"; elif [[ -n "${args['--ro']:-${flag_ro:-}}" ]]; then echo "ro"; else echo "rw"; fi
}

# --init-md: path do markdown inicial (relativo ao mount); vazio se arquivo não existe
# Valor vem de flag_init_md (run seta de args) ou LEECH_INITIAL_MD. Default contexto.md é no bashly (--init-md sem arg).
leech_initial_md() {
  local mount="${1:-}"
  local f="${flag_init_md:-${LEECH_INITIAL_MD:-}}"
  [[ -z "$f" ]] && return 0
  local full="$mount/$f"
  [[ -f "$full" ]] && echo "$f" || echo ""
}

# --danger: sufixo/args de bypass de permissões por engine (vazio se flag não setada).
# Config ~/.leech: DANGER=true deixa danger sempre ligado.
leech_danger_flag() {
  if [[ -z "${flag_danger:-${args['--danger']:-${LEECH_DANGER:-}}}" ]]; then
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
leech_resolve_model_id() {
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
# Ordem: --model= (CLI) > model_<engine>= (~/.leech) > model= (~/.leech).
leech_model_flag() {
  local engine="${1:-}"
  local cli_flag="${args['--model']:-${flag_model:-}}"
  local per_engine=""
  case "${engine,,}" in
    claude)   per_engine="${LEECH_MODEL_CLAUDE:-}" ;;
    opencode) per_engine="${LEECH_MODEL_OPENCODE:-}" ;;
    cursor)   per_engine="${LEECH_MODEL_CURSOR:-}" ;;
  esac
  local m="${cli_flag:-${per_engine:-$LEECH_MODEL}}"
  local id
  id="$(leech_resolve_model_id "$m")"
  [[ -n "$id" ]] && echo "--model $id" || echo ""
}

# Resolve model ID bruto (sem flag prefix) para engines como opencode que usam env var.
# Ordem: --model= (CLI) > model_opencode= (~/.leech) > model= (~/.leech).
leech_model_id() {
  local engine="${1:-}"
  local cli_flag="${args['--model']:-${flag_model:-}}"
  local per_engine=""
  case "${engine,,}" in
    claude)   per_engine="${LEECH_MODEL_CLAUDE:-}" ;;
    opencode) per_engine="${LEECH_MODEL_OPENCODE:-}" ;;
    cursor)   per_engine="${LEECH_MODEL_CURSOR:-}" ;;
  esac
  local m="${cli_flag:-${per_engine:-$LEECH_MODEL}}"
  leech_resolve_model_id "$m"
}

# ── Compose env helper ──────────────────────────────────────────────────────
# Exporta as variáveis necessárias para o compose expandir volumes.
# Chamado internamente por leech_session_run; pode ser usado diretamente.
leech_compose_env() {
  export HOME="${HOME:-$(eval echo ~"$(id -un)")}"
  export CLAUDIO_MOUNT="$1"
  export CLAUDIO_MOUNT_OPTS="$2"
  export OBSIDIAN_PATH="$leech_obsidian_path"
}

# ── Unified session runner ──────────────────────────────────────────────────
# Centraliza o dispatch de engine (opencode/claude/cursor) para todas as sessões.
#
# Uso:
#   leech_session_run <engine> <proj_name> <mount_path> <mount_opts> <mode> [engine_args] [extra_volumes]
#
# Parâmetros:
#   engine        - opencode | claude | cursor
#   proj_name     - nome do projeto compose (ex: leech-projects)
#   mount_path    - path absoluto do projeto no host
#   mount_opts    - rw | ro
#   mode          - engine_args string com flags específicas do engine:
#                     --continue, --resume, --resume=UUID, --init-md=file
#                   Flags reconhecidas e mapeadas por engine automaticamente.
#   extra_volumes - string com volumes extras (ex: "-v /var/log/journal:/workspace/logs/host/journal:ro")
#
# O mode "persistent" (up -d + exec) é usado quando opencode precisa de leech persistente.
# Demais engines usam "run --rm -it" (efêmero).
leech_session_run() {
  local engine="$1"
  local proj_name="$2"
  local mount_path="$3"
  local mount_opts="$4"
  local engine_args="${5:-}"
  local extra_volumes="${6:-}"
  # Analysis mode: passa LEECH_ANALYSIS_MODE=1 pro container via env
  local analysis_env=""
  [[ -n "${flag_analysis_mode:-${args['--analysis-mode']:-}}" ]] && analysis_env="-e LEECH_ANALYSIS_MODE=1"

  leech_compose_env "$mount_path" "$mount_opts"

  local danger model

  case "$engine" in
    opencode)
      # Opencode usa up -d + exec (persistent sandbox)
      local oc_envs=()
      oc_envs+=(-e "CLAUDIO_MOUNT=$mount_path")
      oc_envs+=(-e "BOOTSTRAP_SKIP_CLEAR=1")

      # Model
      local _oc_model
      _oc_model="$(leech_model_id opencode)"
      [[ -n "$_oc_model" ]] && oc_envs+=(-e "OPENCODE_MODEL=$_oc_model")

      # Danger
      [[ -n "${flag_danger:-${args['--danger']:-${LEECH_DANGER:-}}}" ]] && oc_envs+=(-e "OPENCODE_PERMISSION_BYPASS=1")

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
        leech_compose_cmd -p "$proj_name" run --rm -it $extra_volumes $analysis_env \
          --entrypoint /entrypoint.sh "${oc_envs[@]}" leech \
          /bin/bash -c 'cd /workspace/mnt && opencode'
      else
        leech_compose_cmd -p "$proj_name" up -d leech
        leech_compose_cmd -p "$proj_name" exec -it -u claude \
          $analysis_env "${oc_envs[@]}" leech bash -c 'cd /workspace/mnt && exec opencode'
      fi
      ;;

    claude)
      model="$(leech_model_flag claude)"
      danger="$(leech_danger_flag claude)"

      # Build claude CLI args
      local claude_args="${model}${danger}"

      # Continue
      [[ "$engine_args" == *"--continue"* ]] && claude_args+=" --continue"

      # Resume
      if [[ "$engine_args" == *"--resume="* ]]; then
        local resume_id="${engine_args#*--resume=}"
        if [[ "$resume_id" == "1" ]]; then
          claude_args+=" --resume"
        else
          # printf %q preserva espaços no nome da sessão ao expandir em bash -c
          claude_args+=" --resume=$(printf '%q' "$resume_id")"
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

      # Session name = mounted folder (shown in header and statusline)
      [[ -n "$mount_path" ]] && claude_args+=" --name ${mount_path##*/}"

      local launch_cmd="bash /workspace/self/scripts/leech-agent-launch.sh ${claude_args}"
      [[ -n "${args['--no-splash']:-}" ]] && launch_cmd=". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude ${claude_args}"
      # Pre-splash no host: aparece imediatamente antes do container subir
      if [[ -z "${args['--no-splash']:-}" ]]; then
        printf '\033[2J\033[H\033[?25l\n'
        printf "  \033[2m[ .. ]\033[0m  \033[2miniciando leech...\033[0m\n"
      fi
      # Nome canônico do container: leech-{slug} (ex: leech-projects, leech-nixos-host)
      local leech_name="leech-${proj_name#leech-}"
      # Shared container: se não há volumes extras, reusa container existente via exec.
      if [[ -z "$extra_volumes" ]]; then
        local cid
        # Busca por nome canônico primeiro (rápido) — funciona mesmo sem CLAUDIO_MOUNT no env
        cid=$(docker ps -q --filter "name=^/${leech_name}$" 2>/dev/null | head -1)
        # Fallback: busca por CLAUDIO_MOUNT — garante 1 container por diretório mesmo com nome diferente
        if [[ -z "$cid" ]]; then
          cid=$(docker ps -q --filter "label=com.docker.compose.service=leech" 2>/dev/null \
            | xargs -r -I{} docker inspect {} \
                --format '{{.Id}} {{range .Config.Env}}{{.}} {{end}}' 2>/dev/null \
            | awk -v mp="CLAUDIO_MOUNT=${mount_path}" \
                '$0 ~ mp {print substr($1,1,12); exit}')
        fi
        if [[ -z "$cid" ]]; then
          # Container não existe: sobe via compose e renomeia para nome canônico.
          leech_compose_cmd -p "$proj_name" up -d leech
          local auto_name
          auto_name=$(docker ps -f "label=com.docker.compose.project=${proj_name}" \
            -f "label=com.docker.compose.service=leech" \
            -f "label=com.docker.compose.oneoff=False" \
            --format "{{.Names}}" | head -1)
          [[ -n "$auto_name" ]] && docker rename "$auto_name" "$leech_name" 2>/dev/null || true
          cid=$(docker ps -q --filter "name=^/${leech_name}$" 2>/dev/null | head -1)
          docker exec -it $analysis_env \
            -e "CLAUDIO_MOUNT=$mount_path" -e "BOOTSTRAP_SKIP_CLEAR=1" "$cid" \
            /bin/bash -c "${launch_cmd}"
        else
          # Container já quente: docker exec direto (sem parsear compose YAML).
          docker exec -it $analysis_env \
            -e "CLAUDIO_MOUNT=$mount_path" "$cid" \
            /bin/bash -c "cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude ${claude_args}"
        fi
      else
        # run --rm com nome curto: leech-{6chars}
        local short_id
        short_id=$(tr -dc 'a-z0-9' < /dev/urandom 2>/dev/null | head -c 6 || date +%s | tail -c 6)
        leech_compose_cmd -p "$proj_name" run --rm -it --name "leech-${short_id}" \
          $extra_volumes $analysis_env \
          --entrypoint /entrypoint.sh -e "CLAUDIO_MOUNT=$mount_path" -e "BOOTSTRAP_SKIP_CLEAR=1" leech \
          /bin/bash -c "${launch_cmd}"
      fi
      printf '\033[?25h'
      ;;

    cursor)
      danger="$(leech_danger_flag cursor)"
      model="$(leech_model_flag cursor)"
      local name_flag=""
      [[ -n "$mount_path" ]] && name_flag=" --name ${mount_path##*/}"
      local agent_flags="${danger}${model:+ $model}${name_flag}"

      local cursor_envs=()
      cursor_envs+=(-e "CLAUDIO_MOUNT=$mount_path")
      cursor_envs+=(-e "BOOTSTRAP_SKIP_CLEAR=1")

      local agent_check='agent --version >/dev/null 2>&1 || { echo "leech: cursor-agent nao funciona (versao expirada ou imagem desatualizada). Rode: leech build" >&2; exit 1; }; '
      local cursor_cmd=". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt; ${agent_check}"

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

      leech_compose_cmd -p "$proj_name" run --rm -it $extra_volumes $analysis_env \
        --entrypoint /entrypoint.sh "${cursor_envs[@]}" leech \
        /bin/bash -c "$cursor_cmd"
      ;;

    *)
      echo "leech: engine inválido: $engine (use opencode|claude|cursor)" >&2
      exit 1
      ;;
  esac
}

# Helper: lança sessão com engine forçado — usado por leech cursor/opencode/claude new
# Uso: leech_launch_session <engine>
leech_launch_session() {
  local forced_engine="$1"
  args['--engine']="$forced_engine"
  leech_load_config
  local mount_path engine engine_args init_md
  mount_path="$(leech_resolve_dir)"
  local mount_opts slug proj_name
  mount_opts="$(leech_mount_opts)"
  slug="$(leech_proj_slug "$mount_path")"
  proj_name="$(leech_proj_name "$slug")"
  engine="$(leech_resolve_engine 1)"
  engine_args=""
  local resume="${args['--resume']:-}"
  [[ -n "$resume" ]] && engine_args+=" --resume=$resume"
  init_md="$(leech_initial_md "$mount_path")"
  [[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"
  leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
}
