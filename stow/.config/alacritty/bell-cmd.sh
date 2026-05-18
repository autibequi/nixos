#!/usr/bin/env bash
# Bell command do Alacritty. Toca beep curto via sox/pactl/mpv (paths absolutos
# pra evitar colisão com binários homônimos no $PATH, ex: ~/.local/bin/play
# de outros projetos). Loga em /tmp/alacritty-bell.log pra debug.
set -u
LOG=/tmp/alacritty-bell.log
NIX=/run/current-system/sw/bin
{
  echo "=== $(date '+%H:%M:%S.%N') BELL ==="
} >> "$LOG" 2>&1

try() {
  echo "  + try: $*" >> "$LOG"
  "$@" >> "$LOG" 2>&1
}

# 1) sox — gera cada nota separada e concatena (R2D2)
if [ -x "$NIX/sox" ] && [ -x "$NIX/play" ]; then
  D=$(mktemp -d /tmp/bell-XXXX)
  SOX="$NIX/sox"
  # notas: duração(s) frequência_início:frequência_fim volume
  notes=(
    "0.04 600:900   0.14"
    "0.02 900:500   0.14"
    "0.06 700:700   0.11"
    "0.03 450:800   0.15"
    "0.05 750:550   0.12"
    "0.02 800:600   0.13"
    "0.04 550:750   0.11"
  )
  files=()
  i=0
  for n in "${notes[@]}"; do
    read -r dur freq vol <<< "$n"
    f="$D/n${i}.wav"
    "$SOX" -n -r 44100 "$f" synth "$dur" sin "$freq" vol "$vol" 2>>"$LOG"
    files+=("$f")
    (( i++ ))
  done
  "$SOX" "${files[@]}" "$D/r2d2.wav" 2>>"$LOG"
  "$SOX" "$D/r2d2.wav" -d >>"$LOG" 2>&1
  rm -rf "$D"
  echo "  OK: sox r2d2" >> "$LOG"
elif [ -x "$NIX/play" ] && try "$NIX/play" -q -n synth 0.15 sin 1400:2200 vol 0.6; then
  echo "  OK: $NIX/play (sox fallback simples)" >> "$LOG"
# 2) pactl com sample-load (mais leve que paplay)
elif [ -x "$NIX/paplay" ] && try "$NIX/paplay" /run/current-system/sw/share/sounds/freedesktop/stereo/bell.oga; then
  echo "  OK: paplay freedesktop" >> "$LOG"
# 3) mpv (path absoluto)
elif [ -x "$NIX/mpv" ] && try "$NIX/mpv" --no-terminal --really-quiet --length=0.15 'av://lavfi:sine=frequency=880:duration=0.15'; then
  echo "  OK: $NIX/mpv" >> "$LOG"
# 4) canberra-gtk-play
elif [ -x "$NIX/canberra-gtk-play" ] && try "$NIX/canberra-gtk-play" -i bell; then
  echo "  OK: canberra" >> "$LOG"
else
  echo "  FAIL: nenhum player executável encontrado em $NIX" >> "$LOG"
  ls -la "$NIX" | grep -E 'play|paplay|mpv|canberra' >> "$LOG" 2>&1
fi
