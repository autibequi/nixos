#!/usr/bin/env bash
# github.dashboard.sh — PRs, reviews, dirty repos, worktrees, conversations

[[ -f "$AUTOJARVIS_FLAG" ]] && command -v gh &>/dev/null || return 0

# ── Load gh-status cache ─────────────────────────────────────────────────────
WS="$WS" source "$WS/stow/.claude/scripts/gh-status.sh" 2>/dev/null || true
[[ -f "${GH_STATUS_CACHE:-}" ]] && source "${GH_STATUS_CACHE}" 2>/dev/null || true
( gh_status_fetch 2>/dev/null ) &

title_max=$(( COLS - 26 ))
[[ $title_max -lt 20 ]] && title_max=20

# ── PRs meus ─────────────────────────────────────────────────────────────────
if [[ -n "${GH_MY_PRS_COUNT:-}" ]]; then
  echo -e "${P_CYAN}PRs meus:${R} ${P_AMBER}${GH_MY_PRS_COUNT}${R} abertos"

  if [[ -n "${GH_MY_PRS:-}" ]]; then
    count=0
    while IFS='|' read -r repo title url; do
      [[ -z "$repo" ]] && continue
      [[ $count -ge 5 ]] && break
      [[ ${#title} -gt $title_max ]] && title="${title:0:$((title_max - 3))}..."
      pr_num="${url##*/}"
      printf "  ${P_GREEN}▸${R} ${P_DIM}%-16s${R} %s ${P_DIM}#%s${R}\n" "$repo" "$title" "$pr_num"
      count=$((count + 1))
    done <<< "$GH_MY_PRS"
  fi

  # ── Review requests ──────────────────────────────────────────────────────
  if [[ -n "${GH_REVIEW_PRS:-}" ]]; then
    echo -e "${P_CYAN}Review:${R} ${P_AMBER}${GH_REVIEW_COUNT}${R} aguardando"
    review_max=$(( title_max - 20 ))
    [[ $review_max -lt 20 ]] && review_max=20
    count=0
    while IFS='|' read -r repo title author url; do
      [[ -z "$repo" ]] && continue
      [[ $count -ge 5 ]] && break
      [[ ${#title} -gt $review_max ]] && title="${title:0:$((review_max - 3))}..."
      pr_num="${url##*/}"
      printf "  ${P_MAGENTA}◆${R} ${P_DIM}%-16s${R} %s ${P_DIM}(%s) #%s${R}\n" "$repo" "$title" "$author" "$pr_num"
      count=$((count + 1))
    done <<< "$GH_REVIEW_PRS"
  fi
else
  echo -e "${P_DIM}(gh indisponível ou sem dados)${R}"
fi

# ── Dirty repos ──────────────────────────────────────────────────────────────
PROJECTS_ESTRATEGIA="${PROJECTS_ESTRATEGIA:-/home/claude/projects/estrategia}"
[[ ! -d "$PROJECTS_ESTRATEGIA" && -d "$HOME/projects/estrategia" ]] && PROJECTS_ESTRATEGIA="$HOME/projects/estrategia"
dirty_repos=()
for repo in "$PROJECTS_ESTRATEGIA"/*/; do
  [[ -d "$repo/.git" ]] || continue
  name=$(basename "$repo")
  [[ "$name" == "bo-container" || "$name" == "monolito" || "$name" == "front-student" ]] && continue
  dirty=$(git -C "$repo" status --short 2>/dev/null | wc -l)
  branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "?")
  ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "0")
  [[ "$ahead" -gt 0 ]] || continue
  dirty_repos+=("$(printf "  ${P_AMBER}●${R} ${P_DIM}%-16s${R} [%s] ${P_AMBER}dirty:%s${R} ${P_GREEN}ahead:%s${R}" "$name" "$branch" "$dirty" "$ahead")")
done
if [[ ${#dirty_repos[@]} -gt 0 ]]; then
  echo -e "${P_CYAN}Repos com mudanças:${R} ${#dirty_repos[@]}"
  for line in "${dirty_repos[@]:0:6}"; do
    echo -e "$line"
  done
  remaining=$(( ${#dirty_repos[@]} - 6 ))
  [[ $remaining -gt 0 ]] && echo -e "  ${P_DIM}+${remaining} mais${R}"
fi

# ── Worktrees ────────────────────────────────────────────────────────────────
prunable=$(git -C "$WS" worktree list 2>/dev/null | grep -c prunable || true)
active_wt=$(git -C "$WS" worktree list 2>/dev/null | grep -cv "prunable\|$WS " || true)
[[ $prunable -gt 0 ]] && echo && echo -e "${P_CYAN}Worktrees:${R} ${active_wt} ativos, ${P_AMBER}${prunable} prunable${R} ${P_DIM}(git worktree prune)${R}"

echo

# ── Recent conversations (open PRs/issues) ───────────────────────────────────
conv_lines=$(WS="$WS" CONV_LIMIT=5 bash "$WS/stow/.claude/scripts/recent-conversations.sh" 2>/dev/null || true)
if [[ -n "$conv_lines" ]]; then
  echo -e "${P_CYAN}GitHub abertos:${R}"
  conv_max=$(( COLS - 40 ))
  [[ $conv_max -lt 20 ]] && conv_max=20
  while IFS='|' read -r dt kind repo title url; do
    [[ -z "$dt" ]] && continue
    [[ ${#title} -gt $conv_max ]] && title="${title:0:$((conv_max - 3))}..."
    if [[ "$kind" == "PR" ]]; then
      icon="${P_GREEN}▸${R}"
    else
      icon="${P_AMBER}○${R}"
    fi
    local_num="${url##*/}"
    printf "  %b ${P_DIM}%s${R}  ${P_DIM}%-16s${R} %s ${P_DIM}#%s${R}\n" "$icon" "$dt" "$repo" "$title" "$local_num"
  done <<< "$conv_lines"
  echo
fi
