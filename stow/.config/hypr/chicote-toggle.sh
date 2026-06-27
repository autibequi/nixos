#!/usr/bin/env bash
# Toggle do modo chicote. Mata se já roda; senão esconde o cursor, sobe o app
# e — quando ele morre (ESC ou kill) — restaura o cursor. Um wrapper só dono do
# estado do cursor cobre os dois caminhos de saída.

if pkill -x chicote; then
    exit 0
fi

# ponytail: 'cursor:invisible' é o nome conhecido no Hyprland. Se a versão não
# tiver, o hyprctl só loga erro e o chicote segue desenhado junto do cursor real.
hyprctl keyword cursor:invisible true

chicote &
pid=$!
pkill -RTMIN+12 waybar   # mostra o 🥁 na waybar (signal 12)

wait "$pid"

hyprctl keyword cursor:invisible false
pkill -RTMIN+12 waybar   # esconde o 🥁
