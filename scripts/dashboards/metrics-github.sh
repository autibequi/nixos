#!/usr/bin/env bash
# metrics-github.sh — Collect GitHub metrics across repos for IT manager dashboard
# Usage: metrics-github.sh [--dry-run] [--output FILE] [--days N] [--org ORG]
# Requires: gh (authenticated), jq, curl

set -euo pipefail

# ── Math helper (no bc dependency) ───────────────────────────────────────────
calc() { python3 -c "print($1)" 2>/dev/null || echo "0"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
ORG="estrategiahq"
DAYS=30
DRY_RUN=false
OUTPUT=""
REPOS=(
  monolito
  backend-libs
  front-student
  ecommerce
  search
  search-service
  platform-cluster
  bo-container
  coruja-web-ui
)

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --output)    OUTPUT="$2"; shift 2 ;;
    --days)      DAYS="$2"; shift 2 ;;
    --org)       ORG="$2"; shift 2 ;;
    --repos)     IFS=',' read -ra REPOS <<< "$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--output FILE] [--days N] [--org ORG] [--repos r1,r2]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SINCE=$(date -u -d "${DAYS} days ago" +%Y-%m-%dT00:00:00Z 2>/dev/null \
     || date -u -v-${DAYS}d +%Y-%m-%dT00:00:00Z 2>/dev/null \
     || date -u +%Y-%m-%dT00:00:00Z)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date +%Y-%m-%d)

# ── Dry-run sample data ──────────────────────────────────────────────────────
generate_sample_data() {
  cat <<'SAMPLE'
{
  "meta": {
    "generated_at": "2026-03-14T12:00:00Z",
    "org": "estrategiahq",
    "period_days": 30,
    "since": "2026-02-12T00:00:00Z",
    "repos_scanned": ["monolito","backend-libs","front-student","ecommerce","search","search-service","platform-cluster","bo-container","coruja-web-ui"],
    "dry_run": true
  },
  "commits_by_author": {
    "alice": { "total": 87, "repos": {"monolito": 45, "backend-libs": 22, "ecommerce": 20} },
    "bob": { "total": 63, "repos": {"front-student": 40, "coruja-web-ui": 23} },
    "carol": { "total": 51, "repos": {"monolito": 30, "search": 11, "search-service": 10} },
    "dave": { "total": 34, "repos": {"platform-cluster": 20, "bo-container": 14} },
    "eve": { "total": 12, "repos": {"monolito": 8, "backend-libs": 4} },
    "frank": { "total": 5, "repos": {"monolito": 5} },
    "grace": { "total": 2, "repos": {"front-student": 2} }
  },
  "prs_by_author": {
    "alice":  { "opened": 14, "merged": 12, "reviews_given": 23, "avg_review_time_hours": 4.2 },
    "bob":    { "opened": 11, "merged": 9,  "reviews_given": 18, "avg_review_time_hours": 6.8 },
    "carol":  { "opened": 9,  "merged": 8,  "reviews_given": 15, "avg_review_time_hours": 5.1 },
    "dave":   { "opened": 6,  "merged": 5,  "reviews_given": 8,  "avg_review_time_hours": 12.3 },
    "eve":    { "opened": 2,  "merged": 1,  "reviews_given": 1,  "avg_review_time_hours": 48.0 },
    "frank":  { "opened": 1,  "merged": 0,  "reviews_given": 0,  "avg_review_time_hours": null },
    "grace":  { "opened": 0,  "merged": 0,  "reviews_given": 0,  "avg_review_time_hours": null }
  },
  "pr_stats": {
    "total_opened": 43,
    "total_merged": 35,
    "total_open": 8,
    "avg_time_to_merge_hours": 11.4,
    "median_time_to_merge_hours": 6.2,
    "p95_time_to_merge_hours": 48.0
  },
  "low_engagement": [
    { "author": "frank", "commits": 5, "prs_opened": 1, "reviews_given": 0, "reason": "low commits, no reviews" },
    { "author": "grace", "commits": 2, "prs_opened": 0, "reviews_given": 0, "reason": "very low activity across all metrics" }
  ],
  "dora": {
    "deployment_frequency_per_week": 8.75,
    "lead_time_for_changes_hours": 11.4,
    "change_failure_rate_pct": 4.2
  },
  "repos_summary": {
    "monolito":         { "commits": 88, "prs_merged": 15, "contributors": 4 },
    "backend-libs":     { "commits": 26, "prs_merged": 5,  "contributors": 2 },
    "front-student":    { "commits": 42, "prs_merged": 8,  "contributors": 2 },
    "ecommerce":        { "commits": 20, "prs_merged": 3,  "contributors": 1 },
    "search":           { "commits": 11, "prs_merged": 2,  "contributors": 1 },
    "search-service":   { "commits": 10, "prs_merged": 1,  "contributors": 1 },
    "platform-cluster": { "commits": 20, "prs_merged": 4,  "contributors": 1 },
    "bo-container":     { "commits": 14, "prs_merged": 2,  "contributors": 1 },
    "coruja-web-ui":    { "commits": 23, "prs_merged": 5,  "contributors": 1 }
  }
}
SAMPLE
}

if [[ "$DRY_RUN" == "true" ]]; then
  result=$(generate_sample_data)
  if [[ -n "$OUTPUT" ]]; then
    echo "$result" > "$OUTPUT"
    echo "  [dry-run] Sample GitHub metrics written to $OUTPUT" >&2
  else
    echo "$result"
  fi
  exit 0
fi

# ── Helper: safe gh api call with retries ─────────────────────────────────────
gh_api() {
  local endpoint="$1"
  shift
  local attempts=3
  local delay=2
  for ((i=1; i<=attempts; i++)); do
    if result=$(gh api "$endpoint" "$@" 2>/dev/null); then
      echo "$result"
      return 0
    fi
    if [[ $i -lt $attempts ]]; then
      sleep "$delay"
      delay=$((delay * 2))
    fi
  done
  echo "[]"
  return 0
}

# ── Helper: paginate gh api ───────────────────────────────────────────────────
gh_api_paginate() {
  local endpoint="$1"
  shift
  gh api "$endpoint" --paginate "$@" 2>/dev/null || echo "[]"
}

# ── Collect commits per author ────────────────────────────────────────────────
echo "  Collecting GitHub metrics (${DAYS} days, ${#REPOS[@]} repos)..." >&2

declare -A AUTHOR_COMMITS_TOTAL
declare -A AUTHOR_COMMITS_REPOS
declare -A AUTHOR_PRS_OPENED
declare -A AUTHOR_PRS_MERGED
declare -A AUTHOR_REVIEWS
declare -A REPO_COMMITS
declare -A REPO_PRS_MERGED
declare -A REPO_CONTRIBUTORS

ALL_AUTHORS=()
TOTAL_OPENED=0
TOTAL_MERGED=0
TOTAL_OPEN=0
ALL_MERGE_TIMES=()

for repo in "${REPOS[@]}"; do
  echo "    Scanning ${ORG}/${repo}..." >&2

  # Check repo exists
  if ! gh api "repos/${ORG}/${repo}" --silent 2>/dev/null; then
    echo "      repo not found, skipping" >&2
    continue
  fi

  # ── Commits ─────────────────────────────────────────────────────────────
  commits_json=$(gh_api_paginate "repos/${ORG}/${repo}/commits" \
    -f since="$SINCE" -f per_page=100 2>/dev/null || echo "[]")

  repo_commit_count=0
  repo_contribs=()

  while IFS= read -r line; do
    author=$(echo "$line" | jq -r '.author')
    count=$(echo "$line" | jq -r '.count')
    [[ "$author" == "null" || -z "$author" ]] && continue

    repo_commit_count=$((repo_commit_count + count))
    AUTHOR_COMMITS_TOTAL["$author"]=$(( ${AUTHOR_COMMITS_TOTAL["$author"]:-0} + count ))

    existing="${AUTHOR_COMMITS_REPOS["$author"]:-\{\}}"
    AUTHOR_COMMITS_REPOS["$author"]=$(echo "$existing" | jq --arg r "$repo" --argjson c "$count" '. + {($r): $c}')

    if [[ ! " ${ALL_AUTHORS[*]:-} " =~ " ${author} " ]]; then
      ALL_AUTHORS+=("$author")
    fi
    if [[ ! " ${repo_contribs[*]:-} " =~ " ${author} " ]]; then
      repo_contribs+=("$author")
    fi
  done < <(echo "$commits_json" | jq -r '[.[] | {author: (.author.login // .commit.author.name)}] | group_by(.author) | .[] | {author: .[0].author, count: length} | @json' 2>/dev/null || true)

  REPO_COMMITS["$repo"]=$repo_commit_count
  REPO_CONTRIBUTORS["$repo"]=${#repo_contribs[@]}

  # ── PRs ─────────────────────────────────────────────────────────────────
  prs_json=$(gh_api_paginate "repos/${ORG}/${repo}/pulls" \
    -f state=all -f sort=created -f direction=desc -f per_page=100 2>/dev/null || echo "[]")

  # Filter to our date range
  prs_in_range=$(echo "$prs_json" | jq --arg since "$SINCE" '[.[] | select(.created_at >= $since)]' 2>/dev/null || echo "[]")

  repo_merged=0

  while IFS= read -r pr_line; do
    [[ -z "$pr_line" || "$pr_line" == "null" ]] && continue
    pr_author=$(echo "$pr_line" | jq -r '.user')
    pr_state=$(echo "$pr_line" | jq -r '.state')
    pr_merged=$(echo "$pr_line" | jq -r '.merged_at')
    pr_created=$(echo "$pr_line" | jq -r '.created_at')
    pr_number=$(echo "$pr_line" | jq -r '.number')

    [[ "$pr_author" == "null" || -z "$pr_author" ]] && continue

    AUTHOR_PRS_OPENED["$pr_author"]=$(( ${AUTHOR_PRS_OPENED["$pr_author"]:-0} + 1 ))
    TOTAL_OPENED=$((TOTAL_OPENED + 1))

    if [[ ! " ${ALL_AUTHORS[*]:-} " =~ " ${pr_author} " ]]; then
      ALL_AUTHORS+=("$pr_author")
    fi

    if [[ "$pr_merged" != "null" && -n "$pr_merged" ]]; then
      AUTHOR_PRS_MERGED["$pr_author"]=$(( ${AUTHOR_PRS_MERGED["$pr_author"]:-0} + 1 ))
      TOTAL_MERGED=$((TOTAL_MERGED + 1))
      repo_merged=$((repo_merged + 1))

      # Calculate merge time in hours
      created_epoch=$(date -d "$pr_created" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$pr_created" +%s 2>/dev/null || echo "0")
      merged_epoch=$(date -d "$pr_merged" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$pr_merged" +%s 2>/dev/null || echo "0")
      if [[ "$created_epoch" -gt 0 && "$merged_epoch" -gt 0 ]]; then
        diff_hours=$(( (merged_epoch - created_epoch) / 3600 ))
        ALL_MERGE_TIMES+=("$diff_hours")
      fi
    elif [[ "$pr_state" == "open" ]]; then
      TOTAL_OPEN=$((TOTAL_OPEN + 1))
    fi

    # ── Reviews on this PR ────────────────────────────────────────────────
    reviews_json=$(gh_api "repos/${ORG}/${repo}/pulls/${pr_number}/reviews" 2>/dev/null || echo "[]")
    while IFS= read -r reviewer; do
      [[ -z "$reviewer" || "$reviewer" == "null" ]] && continue
      AUTHOR_REVIEWS["$reviewer"]=$(( ${AUTHOR_REVIEWS["$reviewer"]:-0} + 1 ))
      if [[ ! " ${ALL_AUTHORS[*]:-} " =~ " ${reviewer} " ]]; then
        ALL_AUTHORS+=("$reviewer")
      fi
    done < <(echo "$reviews_json" | jq -r '[.[] | .user.login] | unique | .[]' 2>/dev/null || true)

  done < <(echo "$prs_in_range" | jq -c '.[] | {user: .user.login, state: .state, merged_at: .merged_at, created_at: .created_at, number: .number}' 2>/dev/null || true)

  REPO_PRS_MERGED["$repo"]=$repo_merged

done

# ── Compute averages ──────────────────────────────────────────────────────────
avg_merge=0
median_merge=0
p95_merge=0
if [[ ${#ALL_MERGE_TIMES[@]} -gt 0 ]]; then
  sorted_times=($(printf '%s\n' "${ALL_MERGE_TIMES[@]}" | sort -n))
  sum=0
  for t in "${sorted_times[@]}"; do sum=$((sum + t)); done
  avg_merge=$(calc "round($sum / ${#sorted_times[@]}, 1)")
  median_idx=$(( ${#sorted_times[@]} / 2 ))
  median_merge=${sorted_times[$median_idx]}
  p95_idx=$(( ${#sorted_times[@]} * 95 / 100 ))
  [[ $p95_idx -ge ${#sorted_times[@]} ]] && p95_idx=$(( ${#sorted_times[@]} - 1 ))
  p95_merge=${sorted_times[$p95_idx]}
fi

# ── Build JSON output ─────────────────────────────────────────────────────────
# commits_by_author
commits_obj="{}"
for author in "${ALL_AUTHORS[@]}"; do
  total=${AUTHOR_COMMITS_TOTAL["$author"]:-0}
  repos_obj="${AUTHOR_COMMITS_REPOS["$author"]:-\{\}}"
  commits_obj=$(echo "$commits_obj" | jq --arg a "$author" --argjson t "$total" --argjson r "$repos_obj" \
    '. + {($a): {total: $t, repos: $r}}')
done

# prs_by_author
prs_obj="{}"
for author in "${ALL_AUTHORS[@]}"; do
  opened=${AUTHOR_PRS_OPENED["$author"]:-0}
  merged=${AUTHOR_PRS_MERGED["$author"]:-0}
  reviews=${AUTHOR_REVIEWS["$author"]:-0}
  prs_obj=$(echo "$prs_obj" | jq --arg a "$author" \
    --argjson o "$opened" --argjson m "$merged" --argjson rv "$reviews" \
    '. + {($a): {opened: $o, merged: $m, reviews_given: $rv, avg_review_time_hours: null}}')
done

# low_engagement: <10 commits AND <2 reviews
low_engagement="[]"
for author in "${ALL_AUTHORS[@]}"; do
  commits=${AUTHOR_COMMITS_TOTAL["$author"]:-0}
  reviews=${AUTHOR_REVIEWS["$author"]:-0}
  opened=${AUTHOR_PRS_OPENED["$author"]:-0}
  if [[ $commits -lt 10 && $reviews -lt 2 ]]; then
    reason=""
    [[ $commits -lt 5 ]] && reason="very low activity across all metrics" || reason="low commits, no reviews"
    low_engagement=$(echo "$low_engagement" | jq --arg a "$author" \
      --argjson c "$commits" --argjson p "$opened" --argjson r "$reviews" --arg reason "$reason" \
      '. + [{author: $a, commits: $c, prs_opened: $p, reviews_given: $r, reason: $reason}]')
  fi
done

# repos_summary
repos_summary="{}"
for repo in "${REPOS[@]}"; do
  rc=${REPO_COMMITS["$repo"]:-0}
  rm=${REPO_PRS_MERGED["$repo"]:-0}
  rctb=${REPO_CONTRIBUTORS["$repo"]:-0}
  repos_summary=$(echo "$repos_summary" | jq --arg r "$repo" \
    --argjson c "$rc" --argjson m "$rm" --argjson ct "$rctb" \
    '. + {($r): {commits: $c, prs_merged: $m, contributors: $ct}}')
done

# DORA-like
deploy_freq=$(calc "round($TOTAL_MERGED / ($DAYS / 7), 2)")

# Final assembly
result=$(jq -n \
  --arg gen "$NOW" \
  --arg org "$ORG" \
  --argjson days "$DAYS" \
  --arg since "$SINCE" \
  --argjson repos_list "$(printf '%s\n' "${REPOS[@]}" | jq -R . | jq -s .)" \
  --argjson commits_obj "$commits_obj" \
  --argjson prs_obj "$prs_obj" \
  --argjson total_opened "$TOTAL_OPENED" \
  --argjson total_merged "$TOTAL_MERGED" \
  --argjson total_open "$TOTAL_OPEN" \
  --argjson avg_merge "$avg_merge" \
  --argjson median_merge "$median_merge" \
  --argjson p95_merge "$p95_merge" \
  --argjson low_engagement "$low_engagement" \
  --argjson repos_summary "$repos_summary" \
  --argjson deploy_freq "$deploy_freq" \
  '{
    meta: {
      generated_at: $gen,
      org: $org,
      period_days: $days,
      since: $since,
      repos_scanned: $repos_list,
      dry_run: false
    },
    commits_by_author: $commits_obj,
    prs_by_author: $prs_obj,
    pr_stats: {
      total_opened: $total_opened,
      total_merged: $total_merged,
      total_open: $total_open,
      avg_time_to_merge_hours: $avg_merge,
      median_time_to_merge_hours: $median_merge,
      p95_time_to_merge_hours: $p95_merge
    },
    low_engagement: $low_engagement,
    dora: {
      deployment_frequency_per_week: $deploy_freq,
      lead_time_for_changes_hours: $avg_merge,
      change_failure_rate_pct: null
    },
    repos_summary: $repos_summary
  }')

if [[ -n "$OUTPUT" ]]; then
  echo "$result" > "$OUTPUT"
  echo "  GitHub metrics written to $OUTPUT" >&2
else
  echo "$result"
fi
