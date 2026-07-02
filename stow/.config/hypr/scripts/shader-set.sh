#!/usr/bin/env bash
# Shader de tela via `hyprctl eval` — o hyprshade não funciona no Hyprland
# Lua 0.55+ ("keyword can't work with non-legacy parsers"); ele fica só de
# fornecedor dos .glsl.
#
# uso: shader-set.sh <nome> | off | auto | current
set -u

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

shader_dir() {
  local pkg
  pkg=$(dirname "$(dirname "$(readlink -f "$(command -v hyprshade)")")")
  echo "$pkg/share/hyprshade/shaders"
}

set_shader() {
  hyprctl eval "hl.config({ decoration = { screen_shader = '$1' } })"
}

current_shader() {
  hyprctl getoption decoration:screen_shader \
    | awk '/str:/ { print $2 }' \
    | grep -v '\[\[EMPTY\]\]' \
    | xargs -r basename 2>/dev/null | sed 's/\.glsl$//'
}

cmd="${1:-}"
case "$cmd" in
  "" ) echo "uso: shader-set.sh <nome>|off|auto|current" >&2; exit 1 ;;
  current ) current_shader ;;
  off ) set_shader "" ;;
  auto )
    # espelha o schedule do hyprshade/config.toml: blue-light 19:00–06:00,
    # vibrance de dia. ponytail: horário fixo — sunset real = wlsunset/geoclue.
    hour=$(date +%-H)
    if (( hour >= 19 || hour < 6 )); then
      exec "$0" blue-light-filter
    else
      exec "$0" vibrance
    fi
    ;;
  * )
    glsl=$(find "$HOME/.config/hyprshade/shaders" "$HOME/.config/hypr/shaders" "$(shader_dir)" -name "$cmd.glsl" 2>/dev/null | head -1)
    if [ -z "$glsl" ]; then
      notify-send "Shader" "não achei $cmd.glsl" 2>/dev/null
      exit 1
    fi
    set_shader "$glsl"
    ;;
esac
