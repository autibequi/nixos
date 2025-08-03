#!/bin/bash

# Start Hyprland if running on tty1 after logging
[[ $(tty) == /dev/tty1 ]] && exec ~/.config/hypr/init.sh

[[ $(tty) == /dev/tty2 ]] && exec ~/.config/gamescope.sh

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

disk_benchmark() {
  dd if=/dev/zero of=/tmp/test.img bs=1M count=1024 status=progress
  rm -f /tmp/test.img
}
