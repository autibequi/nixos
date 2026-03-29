# Shell init (sourced from shell.nix)
# Usage: available in every zsh session after dotfiles stow


# Pula init interativo em automação (Claude Code, dumb terminals, etc)
if [[ -n "$CLAUDECODE" || "$TERM" == "dumb" ]]; then
  return 0
fi

# Secrets (sempre carrega, Claude precisa das env vars)
source ~/secrets.sh

# Claude Code — esconde do history
HISTORY_IGNORE="(claude*|vennon|vennon*|zion|zion*|puppy*)"

# Shell tool init
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"

# fzf keybindings (Ctrl+T = file, Alt+C = cd, Ctrl+R handled by atuin)
[[ -f /run/current-system/sw/share/fzf/key-bindings.zsh ]] && \
  source /run/current-system/sw/share/fzf/key-bindings.zsh

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
    -loglevel edsadrror \
    "$output_file"

  if [ $? -eq 0 ]; then
    echo "Conversão concluída: '$output_file'"
  else
    echo "Erro durante a conversão."
    return 1
  fi
}

pokemonsay "$(fortune -s)"
