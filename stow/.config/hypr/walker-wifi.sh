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
      ssid = $2;
      signal = $3 + 0;
      security = ($4 == "") ? "open" : $4;
      active = ($1 == "*") ? " · connected" : "";

      if (!(ssid in best_signal) || signal > best_signal[ssid]) {
        best_signal[ssid] = signal;
        best_security[ssid] = security;
        best_active[ssid] = active;
      }
    }
    END {
      for (ssid in best_signal) {
        printf "%s · %d%% · %s%s\n", ssid, best_signal[ssid], best_security[ssid], best_active[ssid]
      }
    }' |
    sort -u |
    "$WALKER" --dmenu --placeholder "Wi-Fi  Enter conecta  Esc cancela  digite filtra"
)"

[ -n "${selection:-}" ] || exit 0

ssid="${selection%% · *}"
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
