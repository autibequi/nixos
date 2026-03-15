#!/usr/bin/env bash
# generate-obsidian-report.sh — Generate Obsidian markdown report from dashboard metrics
# Usage: generate-obsidian-report.sh [--dry-run] [--github FILE] [--jira FILE] [--output DIR]
# Requires: jq

set -euo pipefail

# ── Math helper ──────────────────────────────────────────────────────────────
calc() { python3 -c "print($1)" 2>/dev/null || echo "0"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="/workspace/obsidian/artefacts/dashboard-gestor-ti"

# ── Defaults ──────────────────────────────────────────────────────────────────
DRY_RUN=false
GH_FILE=""
JIRA_FILE=""
OUTPUT_DIR="$VAULT_DIR"
TMPDIR="${TMPDIR:-/tmp}"

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --github)     GH_FILE="$2"; shift 2 ;;
    --jira)       JIRA_FILE="$2"; shift 2 ;;
    --output)     OUTPUT_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--github FILE] [--jira FILE] [--output DIR]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

# ── Collect data ──────────────────────────────────────────────────────────────
if [[ -z "$GH_FILE" ]]; then
  GH_FILE="${TMPDIR}/report-gh-$$.json"
  if [[ "$DRY_RUN" == "true" ]]; then
    bash "${SCRIPT_DIR}/metrics-github.sh" --dry-run --output "$GH_FILE"
  else
    bash "${SCRIPT_DIR}/metrics-github.sh" --output "$GH_FILE"
  fi
fi

if [[ -z "$JIRA_FILE" ]]; then
  JIRA_FILE="${TMPDIR}/report-jira-$$.json"
  if [[ "$DRY_RUN" == "true" ]]; then
    bash "${SCRIPT_DIR}/metrics-jira.sh" --dry-run --output "$JIRA_FILE"
  else
    bash "${SCRIPT_DIR}/metrics-jira.sh" --output "$JIRA_FILE"
  fi
fi

GH=$(cat "$GH_FILE")
JR=$(cat "$JIRA_FILE")

TODAY=$(date +%Y-%m-%d)
REPORT_FILE="${OUTPUT_DIR}/${TODAY}-report.md"

# ── Extract metrics ───────────────────────────────────────────────────────────
gh_total_opened=$(echo "$GH" | jq '.pr_stats.total_opened // 0')
gh_total_merged=$(echo "$GH" | jq '.pr_stats.total_merged // 0')
gh_total_open=$(echo "$GH" | jq '.pr_stats.total_open // 0')
gh_avg_merge=$(echo "$GH" | jq '.pr_stats.avg_time_to_merge_hours // 0')
gh_median_merge=$(echo "$GH" | jq '.pr_stats.median_time_to_merge_hours // 0')
gh_p95_merge=$(echo "$GH" | jq '.pr_stats.p95_time_to_merge_hours // 0')
gh_deploy_freq=$(echo "$GH" | jq '.dora.deployment_frequency_per_week // 0')
gh_period=$(echo "$GH" | jq -r '.meta.period_days // 30')

jr_wip_total=$(echo "$JR" | jq '.wip.total // 0')
jr_aging_count=$(echo "$JR" | jq '.aging.count // 0')
jr_blocked_count=$(echo "$JR" | jq '.blocked.count // 0')
jr_lead_avg=$(echo "$JR" | jq '.lead_time.avg_days // 0')
jr_lead_median=$(echo "$JR" | jq '.lead_time.median_days // 0')
jr_cycle_avg=$(echo "$JR" | jq '.cycle_time.avg_days // 0')
jr_cycle_median=$(echo "$JR" | jq '.cycle_time.median_days // 0')
jr_throughput_wk=$(echo "$JR" | jq '.dora.throughput_per_week // 0')

low_count=$(echo "$GH" | jq '.low_engagement | length')

merge_rate=0
[[ "$gh_total_opened" -gt 0 ]] && merge_rate=$(calc "int($gh_total_merged * 100 / $gh_total_opened)")

# ── Build weekly throughput data for Mermaid ──────────────────────────────────
mermaid_weeks=""
mermaid_values=""
while IFS= read -r entry; do
  week=$(echo "$entry" | jq -r '.week')
  count=$(echo "$entry" | jq '.count')
  mermaid_weeks="${mermaid_weeks}\"${week}\", "
  mermaid_values="${mermaid_values}${count}, "
done < <(echo "$JR" | jq -c '.resolved_per_week[]?' 2>/dev/null)
mermaid_weeks="${mermaid_weeks%, }"
mermaid_values="${mermaid_values%, }"

# ── Build commit distribution for pie chart ───────────────────────────────────
pie_data=""
while IFS= read -r entry; do
  author=$(echo "$entry" | jq -r '.key')
  commits=$(echo "$entry" | jq '.value.total')
  pie_data="${pie_data}    \"${author}\" : ${commits}\n"
done < <(echo "$GH" | jq -c '.commits_by_author | to_entries | sort_by(-.value.total) | .[:8] | .[]' 2>/dev/null)

# ── Build repo distribution for pie chart ─────────────────────────────────────
repo_pie_data=""
while IFS= read -r entry; do
  repo=$(echo "$entry" | jq -r '.key')
  commits=$(echo "$entry" | jq '.value.commits')
  [[ "$commits" -eq 0 ]] && continue
  repo_pie_data="${repo_pie_data}    \"${repo}\" : ${commits}\n"
done < <(echo "$GH" | jq -c '.repos_summary | to_entries | sort_by(-.value.commits) | .[]' 2>/dev/null)

# ── Build leaderboard table ──────────────────────────────────────────────────
leaderboard_rows=""
rank=1
while IFS= read -r entry; do
  author=$(echo "$entry" | jq -r '.key')
  commits=$(echo "$entry" | jq '.commits')
  opened=$(echo "$GH" | jq --arg a "$author" '.prs_by_author[$a].opened // 0')
  merged=$(echo "$GH" | jq --arg a "$author" '.prs_by_author[$a].merged // 0')
  reviews=$(echo "$GH" | jq --arg a "$author" '.prs_by_author[$a].reviews_given // 0')

  score=$((commits + opened * 3 + reviews * 2))
  if [[ $score -gt 50 ]]; then
    status="high"
  elif [[ $score -gt 20 ]]; then
    status="medium"
  else
    status="low"
  fi

  leaderboard_rows="${leaderboard_rows}| ${rank} | ${author} | ${commits} | ${opened} | ${merged} | ${reviews} | ${status} |\n"
  rank=$((rank + 1))
done < <(echo "$GH" | jq -c '[.commits_by_author | to_entries[] | {key: .key, commits: .value.total}] | sort_by(-.commits) | .[]' 2>/dev/null)

# ── Build aging table ─────────────────────────────────────────────────────────
aging_rows=""
while IFS= read -r entry; do
  key=$(echo "$entry" | jq -r '.key')
  summary=$(echo "$entry" | jq -r '.summary')
  assignee=$(echo "$entry" | jq -r '.assignee')
  days=$(echo "$entry" | jq '.days_in_progress')
  priority=$(echo "$entry" | jq -r '.priority')
  aging_rows="${aging_rows}| ${key} | ${summary} | ${assignee} | ${days}d | ${priority} |\n"
done < <(echo "$JR" | jq -c '.aging.issues_over_7_days[]?' 2>/dev/null)

# ── Build blocked table ──────────────────────────────────────────────────────
blocked_rows=""
while IFS= read -r entry; do
  key=$(echo "$entry" | jq -r '.key')
  summary=$(echo "$entry" | jq -r '.summary')
  assignee=$(echo "$entry" | jq -r '.assignee')
  days=$(echo "$entry" | jq '.blocked_days')
  blocked_rows="${blocked_rows}| ${key} | ${summary} | ${assignee} | ${days}d |\n"
done < <(echo "$JR" | jq -c '.blocked.items[]?' 2>/dev/null)

# ── Build low engagement section ──────────────────────────────────────────────
low_eng_section=""
if [[ "$low_count" -gt 0 ]]; then
  low_eng_section="> [!warning] Low Engagement Alert
> **${low_count} developer(s)** with significantly low activity in the last ${gh_period} days.
>
"
  while IFS= read -r entry; do
    author=$(echo "$entry" | jq -r '.author')
    commits=$(echo "$entry" | jq '.commits')
    prs=$(echo "$entry" | jq '.prs_opened')
    reviews=$(echo "$entry" | jq '.reviews_given')
    reason=$(echo "$entry" | jq -r '.reason')
    low_eng_section="${low_eng_section}> - **${author}**: ${commits} commits, ${prs} PRs, ${reviews} reviews — *${reason}*
"
  done < <(echo "$GH" | jq -c '.low_engagement[]?' 2>/dev/null)
fi

# ── Build blocked callout ────────────────────────────────────────────────────
blocked_section=""
if [[ "$jr_blocked_count" -gt 0 ]]; then
  blocked_section="> [!danger] Blocked Items
> **${jr_blocked_count} issue(s)** currently blocked and requiring attention.
"
fi

# ── WIP by project table ─────────────────────────────────────────────────────
wip_proj_rows=""
while IFS= read -r entry; do
  proj=$(echo "$entry" | jq -r '.key')
  count=$(echo "$entry" | jq '.value')
  wip_proj_rows="${wip_proj_rows}| ${proj} | ${count} |\n"
done < <(echo "$JR" | jq -c '.wip.by_project | to_entries | sort_by(-.value) | .[]' 2>/dev/null)

# ── Repo activity table ──────────────────────────────────────────────────────
repo_rows=""
while IFS= read -r entry; do
  repo=$(echo "$entry" | jq -r '.key')
  commits=$(echo "$entry" | jq '.value.commits')
  prs=$(echo "$entry" | jq '.value.prs_merged')
  contribs=$(echo "$entry" | jq '.value.contributors')
  repo_rows="${repo_rows}| ${repo} | ${commits} | ${prs} | ${contribs} |\n"
done < <(echo "$GH" | jq -c '.repos_summary | to_entries | sort_by(-.value.commits) | .[]' 2>/dev/null)

# ── DORA assessment ───────────────────────────────────────────────────────────
dora_deploy_level="Low"
dora_lead_level="Low"
dora_cycle_level="Low"

# Python-based comparisons (no bc dependency)
pycmp() { python3 -c "print(1 if $1 else 0)" 2>/dev/null || echo "0"; }

[[ $(pycmp "$gh_deploy_freq >= 7") == "1" ]] && dora_deploy_level="Elite"
[[ $(pycmp "$gh_deploy_freq >= 3") == "1" && "$dora_deploy_level" == "Low" ]] && dora_deploy_level="High"
[[ $(pycmp "$gh_deploy_freq >= 1") == "1" && "$dora_deploy_level" == "Low" ]] && dora_deploy_level="Medium"

[[ $(pycmp "$jr_lead_avg <= 2") == "1" ]] && dora_lead_level="Elite"
[[ $(pycmp "$jr_lead_avg <= 7") == "1" && "$dora_lead_level" == "Low" ]] && dora_lead_level="High"
[[ $(pycmp "$jr_lead_avg <= 14") == "1" && "$dora_lead_level" == "Low" ]] && dora_lead_level="Medium"

[[ $(pycmp "$jr_cycle_avg <= 1") == "1" ]] && dora_cycle_level="Elite"
[[ $(pycmp "$jr_cycle_avg <= 3") == "1" && "$dora_cycle_level" == "Low" ]] && dora_cycle_level="High"
[[ $(pycmp "$jr_cycle_avg <= 7") == "1" && "$dora_cycle_level" == "Low" ]] && dora_cycle_level="Medium"

# ── Write report ──────────────────────────────────────────────────────────────
cat > "$REPORT_FILE" <<REPORT
---
date: ${TODAY}
category: dashboard
type: engineering-report
reviewed: false
tags:
  - dashboard
  - metrics
  - dora
  - engineering
github_period_days: ${gh_period}
jira_period_weeks: $(echo "$JR" | jq '.meta.period_weeks // 4')
---

# Engineering Dashboard Report — ${TODAY}

## Summary

| Metric | Value | Status |
|--------|-------|--------|
| PRs Opened | ${gh_total_opened} | - |
| PRs Merged | ${gh_total_merged} | $([ "$merge_rate" -ge 80 ] && echo "ok" || echo "warn") |
| Merge Rate | ${merge_rate}% | $([ "$merge_rate" -ge 80 ] && echo "ok" || echo "warn") |
| Open PRs | ${gh_total_open} | $([ "$gh_total_open" -le 10 ] && echo "ok" || echo "warn") |
| WIP Issues | ${jr_wip_total} | $([ "$jr_wip_total" -le 15 ] && echo "ok" || echo "warn") |
| Blocked | ${jr_blocked_count} | $([ "$jr_blocked_count" -eq 0 ] && echo "ok" || echo "danger") |
| Aging (>7d) | ${jr_aging_count} | $([ "$jr_aging_count" -le 2 ] && echo "ok" || echo "warn") |

---

## DORA-Like Metrics

| Metric | Value | Level | Target |
|--------|-------|-------|--------|
| Deployment Frequency | ${gh_deploy_freq}/week | ${dora_deploy_level} | Elite: daily |
| Lead Time for Changes | ${jr_lead_avg} days | ${dora_lead_level} | Elite: <1 day |
| Cycle Time | ${jr_cycle_avg} days | ${dora_cycle_level} | Elite: <1 day |
| PR Merge Time | ${gh_avg_merge}h (median: ${gh_median_merge}h) | - | <24h |

> [!info] DORA Levels
> **Elite**: On-demand deploys, <1d lead time | **High**: Weekly, <1w | **Medium**: Monthly, <1mo | **Low**: Less frequent

---

## Weekly Throughput

\`\`\`mermaid
xychart-beta
    title "Issues Resolved per Week"
    x-axis [${mermaid_weeks}]
    y-axis "Issues Resolved" 0 --> $(echo "$JR" | jq '[.resolved_per_week[]?.count // 0] | max // 50')
    bar [${mermaid_values}]
\`\`\`

| Week | Resolved |
|------|----------|
$(echo "$JR" | jq -r '.resolved_per_week[]? | "| \(.week) | \(.count) |"' 2>/dev/null)
| **Avg/week** | **${jr_throughput_wk}** |

---

## Lead Time & Cycle Time

| Metric | Average | Median | P90 |
|--------|---------|--------|-----|
| Lead Time (created -> resolved) | ${jr_lead_avg}d | ${jr_lead_median}d | $(echo "$JR" | jq '.lead_time.p90_days // 0')d |
| Cycle Time (in-progress -> done) | ${jr_cycle_avg}d | ${jr_cycle_median}d | $(echo "$JR" | jq '.cycle_time.p90_days // 0')d |
| PR Merge Time | ${gh_avg_merge}h | ${gh_median_merge}h | ${gh_p95_merge}h |

---

## Commit Distribution

\`\`\`mermaid
pie title Commits by Developer (${gh_period}d)
$(echo -e "$pie_data")
\`\`\`

---

## GitHub Engagement Leaderboard

| # | Developer | Commits | PRs Opened | PRs Merged | Reviews | Engagement |
|---|-----------|---------|------------|------------|---------|------------|
$(echo -e "$leaderboard_rows")

${low_eng_section}

---

## Repository Activity

\`\`\`mermaid
pie title Commits by Repository (${gh_period}d)
$(echo -e "$repo_pie_data")
\`\`\`

| Repository | Commits | PRs Merged | Contributors |
|------------|---------|------------|--------------|
$(echo -e "$repo_rows")

---

## WIP Health

### Work in Progress by Project

| Project | WIP Count |
|---------|-----------|
$(echo -e "$wip_proj_rows")
| **Total** | **${jr_wip_total}** |

${blocked_section}

### Aging Issues (>7 days in progress)

$(if [[ "$jr_aging_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee | Age | Priority |"
  echo "|-----|---------|----------|-----|----------|"
  echo -e "$aging_rows"
else
  echo "> [!success] No aging issues"
  echo "> All in-progress items are within the 7-day threshold."
fi)

### Blocked Items

$(if [[ "$jr_blocked_count" -gt 0 ]]; then
  echo "| Key | Summary | Assignee | Blocked Days |"
  echo "|-----|---------|----------|--------------|"
  echo -e "$blocked_rows"
else
  echo "> [!success] No blocked items"
  echo "> No issues are currently flagged as blocked."
fi)

---

## Throughput by Assignee

| Assignee | Issues Resolved | Avg Cycle Time |
|----------|----------------|----------------|
$(echo "$JR" | jq -r '.throughput_by_assignee | to_entries | sort_by(-.value.resolved) | .[] | "| \(.key) | \(.value.resolved) | \(.value.avg_cycle_days)d |"' 2>/dev/null)

---

*Report generated automatically by \`generate-obsidian-report.sh\`*
*Data sources: GitHub API (\`gh\`), Jira REST API*
*Tags: #dashboard #metrics #dora #engineering*
REPORT

echo "  Report written to: ${REPORT_FILE}" >&2

# ── Cleanup temp files ────────────────────────────────────────────────────────
[[ -f "${TMPDIR}/report-gh-$$.json" ]] && rm -f "${TMPDIR}/report-gh-$$.json"
[[ -f "${TMPDIR}/report-jira-$$.json" ]] && rm -f "${TMPDIR}/report-jira-$$.json"
