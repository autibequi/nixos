#!/usr/bin/env bash
# Executa o bind escolhido no cheatsheet (menus:shortcuts).
# `hyprctl dispatch` morreu no parser Lua; o registry keymap guarda a action
# e expõe km_trigger() — disparamos via `hyprctl eval`.
set -u

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

combo="${1:-}"
[ -z "$combo" ] && exit 0

# combos vêm do próprio registry (charset seguro); escapa aspas por higiene
combo=${combo//\'/}

exec hyprctl eval "km_trigger('$combo')"
