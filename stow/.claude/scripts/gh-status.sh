#!/usr/bin/env bash
# gh-status.sh — Coleta status GitHub do user (cached)
# Uso: source gh-status.sh && gh_status_fetch
# Output: variáveis GH_MY_PRS, GH_REVIEW_PRS, GH_MY_PRS_COUNT, GH_REVIEW_COUNT
set -euo pipefail

GH_STATUS_CACHE="${WS:-.}/.ephemeral/.gh-status-cache"
GH_STATUS_CACHE_TTL=600  # 10 min

gh_status_fetch() {
  local now; now=$(date +%s)
  local use_cache=0

  if [[ -f "$GH_STATUS_CACHE" ]]; then
    local cache_age; cache_age=$(( now - $(stat -c %Y "$GH_STATUS_CACHE" 2>/dev/null || echo 0) ))
    [[ $cache_age -le $GH_STATUS_CACHE_TTL ]] && use_cache=1
  fi

  if [[ $use_cache -eq 1 ]]; then
    source "$GH_STATUS_CACHE"
    return 0
  fi

  # Fetch from GitHub API
  local my_prs_json review_prs_json

  my_prs_json=$(gh api 'search/issues?q=is:open+is:pr+author:@me&per_page=10' \
    --jq '{count: .total_count, items: [.items[] | {title: .title, repo: (.repository_url | split("/") | .[-1]), url: .html_url, updated: .updated_at}]}' 2>/dev/null || echo '{"count":0,"items":[]}')

  review_prs_json=$(gh api 'search/issues?q=is:open+is:pr+review-requested:@me&per_page=10' \
    --jq '{count: .total_count, items: [.items[] | {title: .title, repo: (.repository_url | split("/") | .[-1]), url: .html_url, author: .user.login, updated: .updated_at}]}' 2>/dev/null || echo '{"count":0,"items":[]}')

  GH_MY_PRS_COUNT=$(echo "$my_prs_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])" 2>/dev/null || echo 0)
  GH_REVIEW_COUNT=$(echo "$review_prs_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['count'])" 2>/dev/null || echo 0)

  # Format my PRs: "repo|title|url"
  GH_MY_PRS=$(echo "$my_prs_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data.get('items', [])[:8]:
    repo = item['repo']
    title = item['title'][:60] + ('...' if len(item['title']) > 60 else '')
    url = item.get('url', '')
    print(f'{repo}|{title}|{url}')
" 2>/dev/null || echo "")

  # Format review PRs: "repo|title|author|url"
  GH_REVIEW_PRS=$(echo "$review_prs_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data.get('items', [])[:8]:
    repo = item['repo']
    title = item['title'][:50] + ('...' if len(item['title']) > 50 else '')
    author = item.get('author', '?')
    url = item.get('url', '')
    print(f'{repo}|{title}|{author}|{url}')
" 2>/dev/null || echo "")

  GH_MY_PRS_JSON="$my_prs_json"
  GH_REVIEW_PRS_JSON="$review_prs_json"

  # Write cache
  mkdir -p "$(dirname "$GH_STATUS_CACHE")" 2>/dev/null || true
  cat > "$GH_STATUS_CACHE" <<CACHE
GH_MY_PRS_COUNT=$GH_MY_PRS_COUNT
GH_REVIEW_COUNT=$GH_REVIEW_COUNT
GH_MY_PRS=$(printf '%q' "$GH_MY_PRS")
GH_REVIEW_PRS=$(printf '%q' "$GH_REVIEW_PRS")
GH_MY_PRS_JSON=$(printf '%q' "$GH_MY_PRS_JSON")
GH_REVIEW_PRS_JSON=$(printf '%q' "$GH_REVIEW_PRS_JSON")
CACHE
}
