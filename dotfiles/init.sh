#!/bin/bash

reset-gnome-extensions() {
  gsettings set org.gnome.shell disable-user-extensions true
  gsettings set org.gnome.shell disable-user-extensions false
  notify-send --expire-time=0 -e \
    --icon=user-trash-full-symbolic \
    --app-name='Gambiarra Manager' \
    'Extensões do GNOME reiniciadas' \
    'Deve ter voltado a funcionar ai, chefe!'
}

convert_video() {
  local input_file="$1"
  local output_file="converted_$(basename "${input_file%.*}").mp4"

  if [ -z "$input_file" ]; then
    echo "Uso: convert_video <arquivo_de_entrada>"
    return 1
  fi

  # Usa pv para mostrar o progresso e ffmpeg com aceleração CUDA para converter o vídeo
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

# Try to run a command directly, fallback to nix-shell if not available
justrun() {
  local cmd="$1"
  shift
  if command -v "$cmd" >/dev/null 2>&1; then
    "$cmd" "$@"
  else
    echo "📦 Comando '$cmd' não encontrado, instalando temporariamente..."
    # Usar pv para mostrar progresso da instalação
    echo "🚀 Executando '$cmd'..."
    NIXPKGS_ALLOW_UNFREE=1 nix-shell -p "$cmd" --run "$cmd $*"
  fi
}

# ZSH HOOK
command_not_found_handler() {
    # Ask for confirmation
    echo -n "O comando não foi encontrado. Instalar com nix-shell e tentar novamente? [y/N] "
    read reply
    if [[ "$reply" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      # Attempt to run the command using nix-shell
      NIXPKGS_ALLOW_UNFREE=1 nix-shell -p "$1" --run "$*" 2>/dev/null || {
        echo "Falha ao executar '$1' com nix-shell. Verifique se o pacote existe."
        return 127
      }
    else
      # If the user declines, print the original error message
      echo "zsh: command not found: $1"
      return 127
    fi
}
