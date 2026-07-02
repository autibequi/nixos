#!/usr/bin/env bash
# clip-toast.sh — disparado por `wl-paste --watch`: acende um toast temporário
# no waybar (módulo custom/cliptoast) + toca um "pop" sempre que algo entra no
# clipboard. Não substitui o watcher do cliphist — roda em paralelo.
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

NIX=/run/current-system/sw/bin
STATE="/tmp/waybar-cliptoast.json"
TIMER="/tmp/waybar-cliptoast.pid"
SIGNAL=13
HOLD=1.5
POP="${HOME}/.config/hypr/sounds/pop.wav"

# wl-paste --watch entrega o conteúdo copiado no stdin; drena pra liberar o pipe.
cat >/dev/null 2>&1

# acende o toast
printf '%s' '{"text":"📋","tooltip":"Copiado pro clipboard","class":"active"}' > "$STATE"
pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null

# pop discreto (em background, não bloqueia) — aplay tem latência ~0, paplay é fallback
if   [ -x "$NIX/aplay"  ]; then "$NIX/aplay" -q "$POP" >/dev/null 2>&1 &
elif [ -x "$NIX/paplay" ]; then "$NIX/paplay" --volume=32768 "$POP" >/dev/null 2>&1 &
fi

# apaga o toast após HOLD; debounce: mata o timer anterior se copiar em sequência
[ -f "$TIMER" ] && kill "$(cat "$TIMER" 2>/dev/null)" 2>/dev/null
(
  sleep "$HOLD"
  printf '%s' '{"text":""}' > "$STATE"
  pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null
  rm -f "$TIMER"
) >/dev/null 2>&1 &
echo "$!" > "$TIMER"

disown -a 2>/dev/null || true
