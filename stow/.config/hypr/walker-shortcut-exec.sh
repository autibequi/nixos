#!/usr/bin/env bash
# Executa o bind escolhido no cheatsheet (menus:shortcuts).
# Mesma lógica do antigo on_select do rofi: acha dispatcher+arg no
# `hyprctl binds` pela tecla final do combo.
set -u

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

combo="${1:-}"
[ -z "$combo" ] && exit 0

key="${combo##*+}"
key="${key// /}"

match=$(hyprctl binds | awk -v k="$key" '
    /^bind/ { reset=1; next }
    reset && /key:/ && index($0, "key: " k) { found=1 }
    reset && /dispatcher:/ && found { sub(/^[ \t]+dispatcher: /, ""); disp=$0 }
    reset && /arg:/ && found { sub(/^[ \t]+arg: /, ""); print disp" "$0; exit }
')

[ -n "$match" ] && exec hyprctl dispatch $match
