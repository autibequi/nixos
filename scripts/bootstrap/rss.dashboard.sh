#!/usr/bin/env bash
# rss.dashboard.sh — RSS digest + feed items for bootstrap dashboard

RSS_DIR="$WS/.ephemeral/rss"
RSS_DIGEST="$RSS_DIR/digest.md"
RSS_DASH="$RSS_DIR/dashboard.txt"

# ── Digest (acima do feed raw) ────────────────────────────────────────────────
if [[ -f "$RSS_DIGEST" ]]; then
  digest_age=$(( $(date +%s) - $(stat -c %Y "$RSS_DIGEST" 2>/dev/null || echo 0) ))
  if [[ $digest_age -lt 7200 ]]; then
    echo -e "${P_CYAN}RSS Digest:${R}  ${P_DIM}($(( digest_age / 60 ))min atrás)${R}"
    grep '^\- ' "$RSS_DIGEST" | head -8 | while IFS= read -r line; do
      echo -e "  ${P_DIM}${line}${R}"
    done
    echo
  fi
fi

# ── Feed items raw ────────────────────────────────────────────────────────────
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
