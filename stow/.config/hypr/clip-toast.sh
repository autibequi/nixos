#!/usr/bin/env bash
# clip-toast.sh — disparado por `wl-paste --watch`: acende um toast temporário
# no waybar (módulo custom/cliptoast) + toca um "pop" sempre que algo entra no
# clipboard. Não substitui o watcher do cliphist — roda em paralelo.
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

STATE="/tmp/waybar-cliptoast.json"
TIMER="/tmp/waybar-cliptoast.pid"
SIGNAL=13
HOLD=1.5
POP="${HOME}/.config/hypr/sounds/pop.wav"

# wl-paste --watch entrega o conteúdo copiado no stdin; drena pra liberar o pipe.
cat >/dev/null 2>&1

# acende o toast
printf '%s' '{"text":"󰅍","tooltip":"Copiado pro clipboard","class":"active"}' > "$STATE"
pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null

# pop (em background, não bloqueia)
[ -f "$POP" ] && pw-play --volume=0.5 "$POP" >/dev/null 2>&1 &

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
