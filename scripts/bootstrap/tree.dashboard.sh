#!/usr/bin/env bash
# tree.dashboard.sh — volumes mount status

volumes=(
  "host"
  "obsidian"
  "mount"
)

line=""
for vol in "${volumes[@]}"; do
  path="$WS/$vol"
  if [[ -d "$path" ]] && [[ -n "$(ls -A "$path" 2>/dev/null)" ]]; then
    line+="${ON}●${R} ${B}${vol}${R}   "
  else
    line+="${OFF}●${R} ${P_DIM}${vol}${R}   "
  fi
done

echo -e "  ${P_DIM}volumes:${R}  $line"
