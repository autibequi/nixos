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
  local obsidian_path="${OBSIDIAN_PATH:-$HOME/.ovault}"

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

  # Default: ~/projects quando sem arg
  if [[ -z "$mount_path" ]]; then
    mount_path="$HOME/projects"
    mount_opts="rw"
  fi

  # Projeto isolado por dir montado
  local proj_slug
  proj_slug="$(basename "${mount_path}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
  proj_slug="${proj_slug%-}"

  local proj_name="clau-${proj_slug}"
  [[ -n "$instance" && "$instance" != "1" ]] && proj_name="${proj_name}-${instance}"

  # Cada sessão é um container efêmero independente — nasce e morre com a sessão
  case "$mode" in
    claude)
      CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="${mount_opts}" OBSIDIAN_PATH="${obsidian_path}" \
        docker compose -f "$compose_file" -p "$proj_name" run --rm -it \
        --entrypoint /bin/bash \
        -e CLAUDIO_MOUNT="${mount_path}" sandbox \
        -c ". /workspace/host/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude ${model} --permission-mode bypassPermissions"
      ;;
    shell)
      CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="${mount_opts}" OBSIDIAN_PATH="${obsidian_path}" \
        docker compose -f "$compose_file" -p "$proj_name" run --rm -it \
        --entrypoint /bin/bash \
        -e CLAUDIO_MOUNT="${mount_path}" sandbox
      ;;
    resume)
      CLAUDIO_MOUNT="${mount_path}" CLAUDIO_MOUNT_OPTS="${mount_opts}" OBSIDIAN_PATH="${obsidian_path}" \
        docker compose -f "$compose_file" -p "$proj_name" run --rm -it \
        --entrypoint /bin/bash \
        -e CLAUDIO_MOUNT="${mount_path}" sandbox \
        -c "exec /home/claude/.nix-profile/bin/claude --resume --permission-mode bypassPermissions"
      ;;
  esac
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

  # Default: ~/projects quando sem arg
  if [[ -z "$mount_path" ]]; then
    mount_path="$HOME/projects"
    mount_opts="rw"
  fi

  local proj_slug="$(basename "${mount_path}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
  proj_slug="${proj_slug%-}"
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
