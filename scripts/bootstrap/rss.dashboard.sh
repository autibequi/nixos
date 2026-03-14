#!/usr/bin/env bash
# rss.dashboard.sh — RSS feed section for bootstrap dashboard

RSS_DASH="$WS/.ephemeral/rss/dashboard.txt"
if [[ -f "$RSS_DASH" ]]; then
  rss_age=$(( $(date +%s) - $(stat -c %Y "$RSS_DASH" 2>/dev/null || echo 0) ))
  if [[ $rss_age -lt 7200 ]]; then
    echo -e "${P_CYAN}RSS:${R}"
    head -5 "$RSS_DASH" | while IFS= read -r line; do
      echo -e "  ${P_DIM}${line}${R}"
    done
    echo
  fi
fi
