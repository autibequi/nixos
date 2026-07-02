#!/usr/bin/env bash
# Toggle do modo chicote. Mata se já roda; senão esconde o cursor, sobe o app
# e — quando ele morre (ESC ou kill) — restaura o cursor. O wait roda em
# background: hl.exec_cmd / waybar on-click não podem bloquear até o chicote
# fechar (isso congela binds e parece que o PC travou).

CURSOR_THEME="${CHICOTE_CURSOR_THEME:-BreezeX-RosePine-Linux}"
CURSOR_SIZE="${CHICOTE_CURSOR_SIZE:-48}"

restore_cursor() {
    hyprctl eval 'hl.config({ cursor = { invisible = false } })' 2>/dev/null || true
    hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" 2>/dev/null || true
    pkill -RTMIN+12 waybar 2>/dev/null || true
}

# GLFW Wayland: class vazia; app_id ajuda Hyprland a reconhecer a janela.
chicote_env() {
    export GLFW_PLATFORM="${GLFW_PLATFORM:-wayland}"
    export WAYLAND_APP_ID="${WAYLAND_APP_ID:-chicote}"
    unset DISPLAY
}

# Fallback se a windowrule demorar: força overlay fullscreen no monitor focado.
apply_overlay() {
    local addr attempts=0
    while [ "$attempts" -lt 20 ]; do
        addr=$(hyprctl clients 2>/dev/null | awk '/Window .* -> chicote:/{print $2}')
        [ -n "$addr" ] && break
        sleep 0.05
        attempts=$((attempts + 1))
    done
    [ -z "$addr" ] && return 1

    hyprctl eval "hl.dsp.window.float({ action = 'on', address = '0x${addr}' })" \
        2>/dev/null || true
    hyprctl eval "hl.dsp.window.pin({ address = '0x${addr}' })" \
        2>/dev/null || true
}

if pgrep -x chicote >/dev/null; then
    pkill -x chicote
    restore_cursor
    exit 0
fi

chicote_env
chicote &
pid=$!

sleep 0.25
if ! kill -0 "$pid" 2>/dev/null; then
    restore_cursor
    exit 1
fi

apply_overlay

hyprctl eval 'hl.config({ cursor = { invisible = true } })' 2>/dev/null || true
pkill -RTMIN+12 waybar   # mostra o 🥁 na waybar (signal 12)

(
    wait "$pid" || true
    restore_cursor
) &
