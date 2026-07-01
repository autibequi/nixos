#!/usr/bin/env bash
# caffeine.sh — idle inhibitor que sobrevive a restart do waybar.
# O inibidor real roda DESACOPLADO (setsid+disown) via systemd-inhibit; o waybar
# só reflete/toggla se esse processo está vivo. Restart do waybar não mata o
# inibidor, então o estado "ligado" persiste sozinho — sem precisar de flag.
set -u
PID_FILE="/tmp/waybar-caffeine.pid"

is_active() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

status() {
  if is_active; then
    printf '{"text":"","class":"activated","tooltip":"Caffeine: ligado (sem suspender/lidswitch)"}\n'
  else
    printf '{"text":"","class":"deactivated","tooltip":"Caffeine: desligado"}\n'
  fi
}

toggle() {
  if is_active; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
  else
    setsid systemd-inhibit --what=idle:sleep:handle-lid-switch \
      --who="waybar-caffeine" --why="toggle manual" sleep infinity &
    echo $! > "$PID_FILE"
    disown
  fi
}

case "${1:-status}" in
  status) status ;;
  toggle) toggle ;;
esac
