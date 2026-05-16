# Shell init (sourced from shell.nix)
# Usage: available in every zsh session after dotfiles stow

export EDITOR=vim
export VISUAL=zeditor

# Pula init interativo em automação (Claude Code, dumb terminals, etc)
if [[ -n "$CLAUDECODE" || "$TERM" == "dumb" ]]; then
  return 0
fi

# Startup Screensaver
# Ghostty sets TERM=xterm-ghostty (not "ghostty"); Alacritty uses alacritty
if [[ "$TERM" == "xterm-ghostty" || "$TERM" == "ghostty" || "$TERM" == "alacritty" ]]; then
  # pokemonsay "$(fortune -s)"
  sleep 0.1 && cbonsai -p -l -t 0,0005 -w $(tput cols)
fi

# Terminal alias for stuff
alias terminal='alacritty'

# Secrets (sempre carrega, Claude precisa das env vars)
source ~/secrets.sh

# fzf keybindings (Ctrl+T = file, Alt+C = cd, Ctrl+R handled by atuin)
[[ -f /run/current-system/sw/share/fzf/key-bindings.zsh ]] && \
  source /run/current-system/sw/share/fzf/key-bindings.zsh

######################
#      Tools init
######################

# Cache dos init scripts — evita fork+exec a cada shell
# Regen: rm ~/.cache/zsh-init-cache/*.zsh
_zsh_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init-cache"
[[ -d "$_zsh_cache_dir" ]] || mkdir -p "$_zsh_cache_dir"

_cache_or_eval() {
  local name="$1"; shift
  local cache="$_zsh_cache_dir/$name.zsh"
  if [[ ! -f "$cache" ]]; then
    "$@" > "$cache"
  fi
  source "$cache"
}

_cache_or_eval starship starship init zsh
_cache_or_eval zoxide  zoxide init zsh
_cache_or_eval atuin   atuin init zsh --disable-up-arrow

######################
#      Functions
######################

# Arruma todos os lint errors da sua branch com o eslint
function nodeLintFix() {
  npx eslint $(git diff --name-only origin/main...HEAD -- '*.js' '*.vue') --config .eslintrc.js --quiet --fix
}

# Convert any video type to mp4 with VAAPI
toMP4() {
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
