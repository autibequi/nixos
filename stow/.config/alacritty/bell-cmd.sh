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

# 1) sox (path absoluto pra não pegar ~/.local/bin/play do user)
if [ -x "$NIX/play" ] && try "$NIX/play" -q -n synth 0.12 sin 880 vol 0.4; then
  echo "  OK: $NIX/play (sox)" >> "$LOG"
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
