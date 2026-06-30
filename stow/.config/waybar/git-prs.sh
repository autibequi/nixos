#!/usr/bin/env bash
# git-prs.sh <approved|pending|review> — conta PRs pro grupo de módulos da waybar.
#   approved = meus PRs abertos já aprovados (prontos pra mergear)
#   pending  = meus PRs abertos ainda não aprovados (aguardando review/changes)
#   review   = PRs onde pediram a minha review (a revisar)
# Uma única query GraphQL alimenta as 3 partes; cacheada em /tmp pra não bater 3× na API.
set -u

part="${1:-pending}"
cache=/tmp/waybar-git-prs.json
ttl=90

stale=1
if [ -f "$cache" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
  [ "$age" -le "$ttl" ] && stale=0
fi

if [ "$stale" -eq 1 ]; then
  gh api graphql -f query='{
    approved: search(query: "is:open is:pr author:@me review:approved archived:false", type: ISSUE) { issueCount }
    pending:  search(query: "is:open is:pr author:@me -review:approved archived:false", type: ISSUE) { issueCount }
    review:   search(query: "is:open is:pr review-requested:@me archived:false", type: ISSUE) { issueCount }
  }' --jq '{approved:.data.approved.issueCount, pending:.data.pending.issueCount, review:.data.review.issueCount}' \
    > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache"
fi

count=$(jq -r ".${part} // 0" "$cache" 2>/dev/null || echo 0)

case "$part" in
  approved) icon="󰄬"; color="#a6e3a1"; label="aprovados (prontos pra merge)" ;;
  pending)  icon="󱫌"; color="#f9e2af"; label="meus PRs aguardando review" ;;
  review)   icon="󰈈"; color="#89b4fa"; label="PRs aguardando a minha review" ;;
  *)        icon="󰊢"; color="#cdd6f4"; label="PRs" ;;
esac

printf '{"text":"<span foreground=\\"%s\\">%s %s</span>","tooltip":"%s %s","class":"%s"}\n' \
  "$color" "$icon" "$count" "$count" "$label" "$part"
