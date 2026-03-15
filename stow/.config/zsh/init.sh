# Shell init (sourced from shell.nix)
# Usage: available in every zsh session after dotfiles stow

# Secrets (sempre carrega, Claude precisa das env vars)
source ~/secrets.sh

# Claude Code — esconde do history
HISTORY_IGNORE="(claude*|claudio|claudinho|clau|clau-auto)"

# Pula init interativo em automação (Claude Code, dumb terminals, etc)
if [[ -n "$CLAUDECODE" || "$TERM" == "dumb" ]]; then
  return 0
fi

# Shell tool init
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"

# Sources
source ~/.config/hypr/hyprutils.sh

convert_video() {
  local input_file="$1"
  local output_file="converted_$(basename "${input_file%.*}").mp4"

  if [ -z "$input_file" ]; then
    echo "Uso: convert_video <arquivo_de_entrada>"
    return 1
  fi

  ffmpeg \
    -hwaccel vaapi \
    -vaapi_device /dev/dri/renderD128 \
    -i "$input_file" \
    -vf 'format=nv12,hwupload' \
    -c:v h264_vaapi \
    -c:a aac -b:a 192k \
    -loglevel error \
    "$output_file"

  if [ $? -eq 0 ]; then
    echo "Conversão concluída: '$output_file'"
  else
    echo "Erro durante a conversão."
    return 1
  fi
}

# === claudio — entrypoint unificado pro container Claude ===
claudio() {
  local nixos_dir="${CLAUDIO_NIXOS_DIR:-$HOME/nixos}"
  local compose_file="$nixos_dir/docker-compose.claude.yml"
  local mode="claude" model="" mount_path="" mount_opts="ro" instance=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --shell)      mode="shell"; shift ;;
      --resume)     mode="resume"; shift ;;
      --haiku)      model="--model claude-haiku-4-5-20251001"; shift ;;
      --opus)       model="--model claude-opus-4-6"; shift ;;
      -rw)          mount_opts="rw"; shift ;;
      --instance)   instance="$2"; shift 2 ;;
      --instance=*) instance="${1#--instance=}"; shift ;;
      --)           shift; break ;;
      -*)           echo "claudio: unknown flag $1"; return 1 ;;
      *)            mount_path="$(cd "$1" 2>/dev/null && pwd)" || { echo "claudio: dir not found: $1"; return 1; }; shift ;;
    esac
  done

  # Default: CWD, mas skip se é ~/nixos (evita redundância)
  local real_cwd="$(pwd -P)"
  local real_nixos="$(cd "$nixos_dir" 2>/dev/null && pwd -P)"
  if [[ -z "$mount_path" && "$real_cwd" != "$real_nixos" ]]; then
    mount_path="$real_cwd"
  fi

  # Projeto isolado por dir montado (ou "nixos" pra modo meta)
  local proj_slug
  proj_slug="$(basename "${mount_path:-nixos}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//')"

  # Resolve instância: cada instância = container separado + data dir separado
  local claude_data proj_name
  local base_data
  [[ -z "$mount_path" ]] \
    && base_data="${HOME}/.local/share/claude-code" \
    || base_data="${HOME}/.local/share/claude-code-${proj_slug}"

  if [[ -n "$instance" ]]; then
    [[ "$instance" == "1" ]] && claude_data="$base_data" || claude_data="${base_data}-${instance}"
    [[ "$instance" == "1" ]] && proj_name="clau-${proj_slug}" || proj_name="clau-${proj_slug}-${instance}"
    mkdir -p "$claude_data"
    CLAUDE_DATA_DIR="$claude_data" CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="$mount_opts" \
      docker compose -f "$compose_file" -p "$proj_name" up -d --no-recreate sandbox
  else
    # auto: encontra próximo slot livre — com lock pra evitar race condition
    local lockdir="${TMPDIR:-/tmp}/claudio-${proj_slug}.lock"
    local n=1
    claude_data="$base_data"
    proj_name="clau-${proj_slug}"
    (
      # lock atômico: mkdir é operação atômica no Linux
      while ! mkdir "$lockdir" 2>/dev/null; do sleep 0.2; done
      trap "rmdir '$lockdir' 2>/dev/null" EXIT

      while docker compose -f "$compose_file" -p "$proj_name" ps sandbox 2>/dev/null | grep -qE 'running|starting|Up'; do
        (( n++ ))
        claude_data="${base_data}-${n}"
        proj_name="clau-${proj_slug}-${n}"
      done
      mkdir -p "$claude_data"
      # Sobe o container dentro do lock pra garantir que o slot fica reservado
      CLAUDE_DATA_DIR="$claude_data" CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="$mount_opts" \
        docker compose -f "$compose_file" -p "$proj_name" up -d --no-recreate sandbox
      # Exporta vars pro shell pai via arquivo temporário
      printf 'claude_data=%s\nproj_name=%s\n' "$claude_data" "$proj_name" > "${lockdir}.result"
    )
    # Lê resultado do subshell
    if [[ -f "${lockdir}.result" ]]; then
      claude_data=$(grep '^claude_data=' "${lockdir}.result" | cut -d= -f2-)
      proj_name=$(grep '^proj_name=' "${lockdir}.result" | cut -d= -f2-)
      rm -f "${lockdir}.result"
    fi
  fi

  local _compose_env="CLAUDE_DATA_DIR=$claude_data CLAUDIO_MOUNT=${mount_path} CLAUDIO_MOUNT_OPTS=$mount_opts"

  # Para o container ao sair para liberar o slot para próxima sessão
  trap "env $_compose_env docker compose -f '$compose_file' -p '$proj_name' stop sandbox 2>/dev/null" EXIT INT TERM

  case "$mode" in
    claude)
      env $_compose_env docker compose -f "$compose_file" -p "$proj_name" exec -it \
        -e CLAUDIO_MOUNT="${mount_path}" sandbox bash -c \
        ". /workspace/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude ${model} --permission-mode bypassPermissions"
      ;;
    shell)
      env $_compose_env docker compose -f "$compose_file" -p "$proj_name" exec -it \
        -e CLAUDIO_MOUNT="${mount_path}" sandbox bash
      ;;
    resume)
      env $_compose_env docker compose -f "$compose_file" -p "$proj_name" exec -it \
        -e CLAUDIO_MOUNT="${mount_path}" sandbox \
        /home/claude/.nix-profile/bin/claude --resume --permission-mode bypassPermissions
      ;;
  esac

  trap - EXIT INT TERM
}

# === codio — entrypoint opencode com mount do projeto ===
codio() {
  local nixos_dir="${CLAUDIO_NIXOS_DIR:-$HOME/nixos}"
  local compose="docker compose -f $nixos_dir/docker-compose.claude.yml"
  local mount_path="" mount_opts="ro"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -rw) mount_opts="rw"; shift ;;
      --) shift; break ;;
      -*) echo "codio: unknown flag $1"; return 1 ;;
      *)  mount_path="$(cd "$1" 2>/dev/null && pwd)" || { echo "codio: dir not found: $1"; return 1; }; shift ;;
    esac
  done

  # Default: CWD, mas skip se é ~/nixos
  local real_cwd="$(pwd -P)"
  local real_nixos="$(cd "$nixos_dir" 2>/dev/null && pwd -P)"
  if [[ -z "$mount_path" && "$real_cwd" != "$real_nixos" ]]; then
    mount_path="$real_cwd"
  fi

  local proj_slug="$(basename "${mount_path:-nixos}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//')"
  local proj_name="codio-${proj_slug}"

  echo "[codio] ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
  CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="$mount_opts" \
    docker compose -f "$nixos_dir/docker-compose.claude.yml" -p "$proj_name" up -d codio
  CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="$mount_opts" \
    docker compose -f "$nixos_dir/docker-compose.claude.yml" -p "$proj_name" exec -it \
    -e CLAUDIO_MOUNT="${mount_path}" codio bash -c \
    'cd /workspace/mount && exec opencode'
}

# Legacy aliases (compatibilidade)
claudinho() {
  export CLAUDE_SESSION="${CLAUDE_SESSION:-pessoal}"
  local _cwd="${PWD}"
  cd ~/nixos && claudio "${@:-$_cwd}"
}
clau()      { export CLAUDE_SESSION="${CLAUDE_SESSION:-worker}"; cd ~/nixos && make run; }
clau-auto() { export CLAUDE_SESSION="auto"; cd ~/nixos && make auto; }

pokemonsay "$(fortune -s)"
