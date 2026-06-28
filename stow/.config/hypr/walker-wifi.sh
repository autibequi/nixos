#!/usr/bin/env bash
set -euo pipefail

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"
WALKER="${HOME}/.config/hypr/walker-launch.sh"

notify() {
  notify-send "Wi-Fi" "$1" 2>/dev/null || true
}

nmcli radio wifi on >/dev/null 2>&1 || true
nmcli device wifi rescan >/dev/null 2>&1 &

selection="$(
  nmcli --terse --escape no --fields IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no |
    awk -F: 'length($2) {
      active = ($1 == "*") ? "connected" : "";
      security = ($4 == "") ? "open" : $4;
      printf "%s\t%s\t%s%%\t%s\n", $2, active, $3, security
    }' |
    sort -u |
    "$WALKER" --dmenu --placeholder "Wi-Fi networks"
)"

[ -n "${selection:-}" ] || exit 0

ssid="${selection%%$'\t'*}"
[ -n "$ssid" ] || exit 0

if nmcli device wifi connect "$ssid" >/tmp/walker-wifi.log 2>&1; then
  notify "Connected to ${ssid}"
  pkill -RTMIN+1 waybar 2>/dev/null || true
  exit 0
fi

password="$(printf "" | "$WALKER" --dmenu --inputonly --password --placeholder "Password for ${ssid}")"
[ -n "${password:-}" ] || {
  notify "Could not connect to ${ssid}"
  exit 1
}

if nmcli device wifi connect "$ssid" password "$password" >/tmp/walker-wifi.log 2>&1; then
  notify "Connected to ${ssid}"
  pkill -RTMIN+1 waybar 2>/dev/null || true
else
  notify "Connection failed for ${ssid}"
  exit 1
fi
