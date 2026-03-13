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

# === Claude Modes ===
claudinho() { export CLAUDE_SESSION="${CLAUDE_SESSION:-pessoal}"; cd ~/nixos && make sandbox; }
claudio()   { export CLAUDE_SESSION="${CLAUDE_SESSION:-trabalho}"; cd ~/projects/estrategia/claudio && make claude; }
clau()      { export CLAUDE_SESSION="${CLAUDE_SESSION:-worker}"; cd ~/nixos && make run; }
clau-auto() { export CLAUDE_SESSION="auto"; cd ~/nixos && make auto; }

pokemonsay "$(fortune -s)"

cd ~/nixos
