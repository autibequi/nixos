#!/usr/bin/env bash
set -u

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

CACHE="${HOME}/.cache/hyprland/screenshot-pending.png"
LAUNCHER="${HOME}/.config/hypr/scripts/walker-launch.sh"

shot_rows=4
shot_row_h=44
shot_chrome=52
shot_h=$((shot_rows * shot_row_h + shot_chrome))

SHOT_ARGS=(
  --hideqa
  --nohints
  --nosearch
  --width 280
  --height "$shot_h"
  --minheight "$shot_h"
  --maxheight "$shot_h"
  --theme dash
  --provider menus:screenshot
)

mkdir -p "${HOME}/.cache/hyprland" "${HOME}/Pictures/Screenshots" "${HOME}/Pictures/printscreens"

# Serviços quentes enquanto o usuário seleciona a região
systemctl --user is-active elephant.service >/dev/null 2>&1 \
  || systemctl --user start elephant.service >/dev/null 2>&1 &
systemctl --user is-active walker.service >/dev/null 2>&1 \
  || systemctl --user start walker.service >/dev/null 2>&1 &

# Preload do menu no elephant em paralelo com slurp
(
  for _ in {1..50}; do
    systemctl --user is-active elephant.service >/dev/null 2>&1 && break
    sleep 0.01
  done
  elephant query "menus:screenshot;;4" >/dev/null 2>&1 || true
) &

region=$(slurp -b "#00d4ff40" -c "#00d4ff" 2>/dev/null) || exit 0
grim -g "$region" "$CACHE"

if walker "${SHOT_ARGS[@]}"; then
  exit 0
fi

exec "$LAUNCHER" --theme dash --provider menus:screenshot
