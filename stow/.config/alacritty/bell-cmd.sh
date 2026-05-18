#!/usr/bin/env bash
# Bell do Alacritty — beep boop, WAV cacheado em /tmp para latência mínima.
set -u
NIX=/run/current-system/sw/bin
CACHE=/tmp/.alacritty-bell.wav

# Gera o WAV na primeira vez (ou se foi deletado)
if [ ! -f "$CACHE" ] && [ -x "$NIX/sox" ]; then
  "$NIX/sox" \
    "|$NIX/sox -n -p synth 0.22 sin 340  fade 0 0.22 0.060 vol 0.62" \
    "|$NIX/sox -n -p synth 0.07 sin 1050 fade 0 0.07 0.015 vol 0.72" \
    "$CACHE" 2>/dev/null
fi

# Toca o cache — aplay tem latência ~0, sox -d é fallback
if [ -f "$CACHE" ]; then
  if   [ -x "$NIX/aplay"  ]; then "$NIX/aplay"  -q "$CACHE" 2>/dev/null
  elif [ -x "$NIX/paplay" ]; then "$NIX/paplay"     "$CACHE" 2>/dev/null
  elif [ -x "$NIX/sox"    ]; then "$NIX/sox"  "$CACHE" -d    2>/dev/null
  fi
elif [ -x "$NIX/paplay" ]; then
  "$NIX/paplay" /run/current-system/sw/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null
fi
