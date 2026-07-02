#!/usr/bin/env bash
set -euo pipefail

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

WALKER="${HOME}/.config/hypr/scripts/walker-launch.sh"
ssid="${1:?SSID required}"
force_ask="${2:-}"

notify() {
  notify-send -a walker-wifi -t 3500 "Wi-Fi" "$1"
}

prompt_password() {
  local pass
  pass="$(
    "$WALKER" --dmenu --password --exit --hideqa --placeholder "Senha de ${ssid}" 2>/dev/null || true
  )"
  pass="${pass//$'\r'/}"
  pass="${pass//$'\n'/}"
  printf '%s' "$pass"
}

if [[ "$force_ask" != "--ask" ]]; then
  if nmcli -w 12 device wifi connect "$ssid" 2>/dev/null; then
    notify "Conectado a ${ssid}"
    exit 0
  fi
fi

pass="$(prompt_password)"
if [[ -z "$pass" ]]; then
  exit 1
fi

if nmcli -w 15 device wifi connect "$ssid" password "$pass"; then
  notify "Conectado a ${ssid}"
else
  notify "Falha ao conectar em ${ssid}"
  exit 1
fi
