#!/usr/bin/env bash
# git-prs.sh — contador de PRs pro módulo custom/git da waybar.
# text: "󰊢 <abertos>:<aguardando review>" — meus PRs abertos : PRs onde fui pedido pra revisar.
set -u

read -r open review < <(
  gh api graphql -f query='{ mine: search(query: "is:open is:pr author:@me archived:false", type: ISSUE) { issueCount } review: search(query: "is:open is:pr review-requested:@me archived:false", type: ISSUE) { issueCount } }' \
    --jq '"\(.data.mine.issueCount) \(.data.review.issueCount)"' 2>/dev/null
)

open=${open:-0}; review=${review:-0}
printf '{"text":"󰊢 %s:%s","tooltip":"%s PR abertos · %s aguardando review"}\n' \
  "$open" "$review" "$open" "$review"
