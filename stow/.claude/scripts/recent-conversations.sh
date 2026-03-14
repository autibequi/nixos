#!/usr/bin/env bash
# recent-conversations.sh — List open GitHub conversations (PRs + issues)
# Output: pipe-separated lines: "updated|type|repo|title|url"
# Usage: CONV_LIMIT=5 bash recent-conversations.sh
set -euo pipefail

CONV_CACHE="${CONV_CACHE:-${WS:-.}/.ephemeral/.recent-conversations}"
CONV_CACHE_TTL="${CONV_CACHE_TTL:-300}"  # 5 min
CONV_LIMIT="${CONV_LIMIT:-5}"

_conv_fetch() {
  local now; now=$(date +%s)
  if [[ -f "$CONV_CACHE" ]]; then
    local age; age=$(( now - $(stat -c %Y "$CONV_CACHE" 2>/dev/null || echo 0) ))
    if [[ $age -le $CONV_CACHE_TTL ]]; then
      head -n "$CONV_LIMIT" "$CONV_CACHE"
      return 0
    fi
  fi

  command -v gh &>/dev/null || return 0

  {
    # Fetch open PRs and issues authored by user, merge and sort by date
    python3 << 'PYEOF' 2>/dev/null
import json, subprocess, sys
from datetime import datetime

results = []

# Open PRs
try:
    out = subprocess.check_output(
        ["gh", "search", "prs", "--author=@me", "--state=open",
         "--limit=15", "--sort=updated",
         "--json", "repository,title,url,updatedAt"],
        stderr=subprocess.DEVNULL, timeout=10
    )
    for pr in json.loads(out):
        repo = pr["repository"]["name"]
        title = pr["title"]
        url = pr["url"]
        updated = pr["updatedAt"]
        dt = datetime.fromisoformat(updated.replace("Z", "+00:00"))
        results.append((dt, f"{dt.strftime('%d/%m %H:%M')}|PR|{repo}|{title}|{url}"))
except Exception:
    pass

# Open issues
try:
    out = subprocess.check_output(
        ["gh", "search", "issues", "--author=@me", "--state=open",
         "--limit=10", "--sort=updated",
         "--json", "repository,title,url,updatedAt"],
        stderr=subprocess.DEVNULL, timeout=10
    )
    for issue in json.loads(out):
        repo = issue["repository"]["name"]
        title = issue["title"]
        url = issue["url"]
        updated = issue["updatedAt"]
        dt = datetime.fromisoformat(updated.replace("Z", "+00:00"))
        results.append((dt, f"{dt.strftime('%d/%m %H:%M')}|Issue|{repo}|{title}|{url}"))
except Exception:
    pass

# Sort by date desc
results.sort(key=lambda x: x[0], reverse=True)
for _, line in results[:20]:
    print(line)
PYEOF
  } > "$CONV_CACHE" 2>/dev/null || true

  head -n "$CONV_LIMIT" "$CONV_CACHE"
}

_conv_fetch
