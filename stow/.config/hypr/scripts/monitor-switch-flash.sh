#!/usr/bin/env bash
# monitor-switch-flash.sh — engrossa a borda da janela ativa por ~1s pra chamar
# atenção ao trocar de monitor (Super+Esc); depois restaura.
#
# O FOCO do monitor é feito no Lua do keybind (hl.dispatch) — aqui é SÓ o flash.
# `hyprctl keyword` morreu no parser Lua ("use eval") → seta via hyprctl eval.
# A cor é gradiente dinâmico → não tocada.
set -u
PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

FLASH_SIZE=8
HOLD=1.0
LOCK="${XDG_RUNTIME_DIR:-/tmp}/monitor-flash-border.orig"

# Salva o border_size REAL só na 1ª chamada — evita gravar o valor já engrossado
# quando se troca de monitor várias vezes seguidas.
if [ ! -f "$LOCK" ]; then
  hyprctl getoption -j general:border_size 2>/dev/null | jq -r '.int // 3' > "$LOCK"
fi

hyprctl eval "hl.config({ general = { border_size = $FLASH_SIZE } })" >/dev/null 2>&1

# Restaura em background (não bloqueia o compositor/keybind).
(
  sleep "$HOLD"
  hyprctl eval "hl.config({ general = { border_size = $(cat "$LOCK" 2>/dev/null || echo 3) } })" >/dev/null 2>&1
  rm -f "$LOCK"
) >/dev/null 2>&1 &

disown 2>/dev/null || true
