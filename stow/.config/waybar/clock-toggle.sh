#!/usr/bin/env bash
# clock-toggle.sh — retorna JSON p/ custom/clock no waybar.
# Estado em /tmp/waybar-clock-long (existe = modo longo; ausente = modo curto).
# Com arg "toggle": inverte estado e sinaliza waybar.
STATE="/tmp/waybar-clock-long"

if [ "${1:-}" = "toggle" ]; then
    [ -f "$STATE" ] && rm -f "$STATE" || touch "$STATE"
    pkill -SIGRTMIN+16 waybar 2>/dev/null || true
    exit 0
fi

if [ -f "$STATE" ]; then
    text="$(date +'%Y-%m-%d  %H:%M:%S')"
    tooltip="modo longo — clique para curto"
else
    text="$(date +'%H:%M')"
    tooltip="$(date +'%A, %d de %B')"
fi

printf '{"text":"󰥔 %s","tooltip":"%s"}\n' "$text" "$tooltip"
