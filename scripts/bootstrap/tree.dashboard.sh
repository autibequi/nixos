#!/usr/bin/env bash
# tree.dashboard.sh — volumes status (vars only, output handled by header)

vol_host="$WS/host"
vol_obsidian="$WS/obsidian"
vol_mount="$WS/mount"

_vol_dot() {
  local path="$1"
  if [[ -d "$path" ]] && [[ -n "$(ls -A "$path" 2>/dev/null)" ]]; then
    echo -ne "${ON}●${R}"
  else
    echo -ne "${OFF}●${R}"
  fi
}

export VOL_HOST_DOT; VOL_HOST_DOT="$(_vol_dot "$vol_host")"
export VOL_OBSIDIAN_DOT; VOL_OBSIDIAN_DOT="$(_vol_dot "$vol_obsidian")"
export VOL_MOUNT_DOT; VOL_MOUNT_DOT="$(_vol_dot "$vol_mount")"
