#!/run/current-system/sw/bin/bash

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
  pv "$input_file" | ffmpeg \
    -hwaccel cuda \
    -hwaccel_output_format cuda \
    -i pipe:0 \
    -c:v h264_nvenc -preset fast \
    -c:a aac -strict experimental -b:a 192k \
    -loglevel error \
    "$output_file"

  if [ $? -eq 0 ]; then
    echo "Conversão concluída: '$output_file'"
  else
    echo "Erro durante a conversão."
    return 1
  fi
}

