#!/usr/bin/env bash
# Atualiza cache do Walker dashboard (status do sistema).
# Leitura síncrona no elephant = instantânea; refresh em background no walker-launch.

set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/elephant"
CACHE="${CACHE_DIR}/dash-status.cache"
TMP="${CACHE}.tmp.$$"
mkdir -p "$CACHE_DIR"

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

shq() {
  timeout 0.45 sh -c "$1" 2>/dev/null | trim || true
}

wifi_line() {
  if [[ "$(shq 'nmcli radio wifi')" != "enabled" ]]; then
    echo "Wi‑Fi desligado"
    return
  fi
  local ssid
  ssid=$(shq "nmcli -t -f NAME,TYPE connection show --active | awk -F: '\$2==\"802-11-wireless\"{print \$1; exit}'")
  if [[ -z "$ssid" ]]; then
    echo "Wi‑Fi · sem rede"
  else
    echo "Wi‑Fi · ${ssid}"
  fi
}

bt_line() {
  if [[ "$(shq "bluetoothctl show | awk '/Powered/{print \$2}'")" != "yes" ]]; then
    echo "BT off"
    return
  fi
  local dev
  dev=$(shq "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-")
  if [[ -z "$dev" ]]; then
    echo "BT · nenhum"
    return
  fi
  [[ ${#dev} -gt 22 ]] && dev="${dev:0:19}…"
  echo "BT · ${dev}"
}

audio_line() {
  local raw muted pct n
  raw=$(shq "wpctl get-volume @DEFAULT_AUDIO_SINK@")
  [[ -z "$raw" ]] && { echo "Áudio · —"; return; }
  muted=$([[ "$raw" == *MUTED* ]] && echo 1 || echo 0)
  pct=$(grep -oE '[0-9]+(\.[0-9]+)?' <<<"$raw" | head -1)
  [[ -z "$pct" ]] && { echo "Áudio · —"; return; }
  n=$(awk -v p="$pct" 'BEGIN{printf "%d", p*100+0.5}')
  if (( muted )); then
    echo "🔇 mudo"
  else
    echo "🔊 ${n}%"
  fi
}

battery_line() {
  local cap ac
  cap=$(shq "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null")
  [[ -z "$cap" ]] && return 0
  ac=$(shq "cat /sys/class/power_supply/ADP0/online 2>/dev/null")
  if [[ "$ac" == "1" ]]; then
    echo "🔌 ${cap}%"
  else
    echo "🔋 ${cap}%"
  fi
}

notif_line() {
  local raw n
  raw=$(shq "swaync-client -swb")
  n=$(grep -oE '"text"[[:space:]]*:[[:space:]]*"[0-9]+"' <<<"$raw" | grep -oE '[0-9]+' | head -1)
  if [[ -n "$n" && "$n" -gt 0 ]]; then
    echo "🔔 ${n}"
  fi
}

# Probes em paralelo (arquivos temp — set -u seguro)
_probe_dir=$(mktemp -d)
trap 'rm -rf "$_probe_dir"' EXIT
wifi_line >"$_probe_dir/wifi" &
bt_line >"$_probe_dir/bt" &
audio_line >"$_probe_dir/audio" &
battery_line >"$_probe_dir/bat" &
notif_line >"$_probe_dir/notif" &
wait
wifi=$(trim <"$_probe_dir/wifi")
bt=$(trim <"$_probe_dir/bt")
audio=$(trim <"$_probe_dir/audio")
bat=$(trim <"$_probe_dir/bat")
notif=$(trim <"$_probe_dir/notif")
rm -rf "$_probe_dir"
trap - EXIT

parts=("$wifi" "$bt" "$audio")
[[ -n "$bat" ]] && parts+=("$bat")
[[ -n "$notif" ]] && parts+=("$notif")

status="${parts[0]}"
for ((i = 1; i < ${#parts[@]}; i++)); do
  status="${status}  ·  ${parts[i]}"
done

cache_line() {
  local key=$1 val=$2
  val=${val//\\/\\\\}
  val=${val//$'\n'/ }
  val=${val//$'\r'/}
  printf '%s=%s\n' "$key" "$val"
}

{
  cache_line ts "$(date +%s)"
  cache_line status "$status"
  cache_line wifi "$wifi"
  cache_line bt "$bt"
  cache_line audio "$audio"
  cache_line battery "$bat"
  cache_line notif "$notif"
} >"$TMP"

mv -f "$TMP" "$CACHE"
