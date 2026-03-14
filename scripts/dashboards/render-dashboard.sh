#!/usr/bin/env bash
# render-dashboard.sh — Beautiful ASCII dashboard for IT manager metrics
# Usage: render-dashboard.sh [--dry-run] [--github FILE] [--jira FILE] [--no-color]
# Requires: jq, python3 (for math), stty (for terminal width)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ──────────────────────────────────────────────────────────────────
DRY_RUN=false
GH_FILE=""
JIRA_FILE=""
NO_COLOR=false
TMPDIR="${TMPDIR:-/tmp}"

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --github)     GH_FILE="$2"; shift 2 ;;
    --jira)       JIRA_FILE="$2"; shift 2 ;;
    --no-color)   NO_COLOR=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--github FILE] [--jira FILE] [--no-color]"
      echo "  --dry-run    Use sample data from metrics scripts"
      echo "  --github F   Read GitHub metrics from file F"
      echo "  --jira F     Read Jira metrics from file F"
      echo "  --no-color   Disable ANSI colors"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Terminal dimensions ───────────────────────────────────────────────────────
if command -v tput &>/dev/null; then
  TERM_WIDTH=$(tput cols 2>/dev/null || echo 100)
elif command -v stty &>/dev/null; then
  TERM_WIDTH=$(stty size 2>/dev/null | cut -d' ' -f2 || echo 100)
else
  TERM_WIDTH=100
fi
[[ -z "$TERM_WIDTH" || "$TERM_WIDTH" == "0" ]] && TERM_WIDTH=100
[[ $TERM_WIDTH -lt 80 ]] && TERM_WIDTH=80
[[ $TERM_WIDTH -gt 140 ]] && TERM_WIDTH=140

# ── Math helper (replaces bc) ────────────────────────────────────────────────
calc() {
  python3 -c "print($1)" 2>/dev/null || echo "0"
}

# ── ANSI strip helper (replaces sed) ─────────────────────────────────────────
strip_ansi() {
  python3 -c "
import re, sys
text = sys.stdin.read()
print(re.sub(r'\x1b\[[0-9;]*m', '', text), end='')
"
}

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ "$NO_COLOR" == "true" ]]; then
  RST="" BLD="" DIM=""
  RED="" GRN="" YLW="" BLU="" CYN="" MAG="" WHT=""
  BRED="" BGRN="" BYLW="" BBLU="" BCYN="" BMAG=""
  BG_RED="" BG_GRN="" BG_YLW=""
else
  RST='\033[0m'    BLD='\033[1m'    DIM='\033[2m'
  RED='\033[31m'   GRN='\033[32m'   YLW='\033[33m'
  BLU='\033[34m'   CYN='\033[36m'   MAG='\033[35m'   WHT='\033[37m'
  BRED='\033[91m'  BGRN='\033[92m'  BYLW='\033[93m'
  BBLU='\033[94m'  BCYN='\033[96m'  BMAG='\033[95m'
  BG_RED='\033[41m' BG_GRN='\033[42m' BG_YLW='\033[43m'
fi

# ── Nerd Font Icons ──────────────────────────────────────────────────────────
IC_GIT=""       # nf-dev-git_branch
IC_PR=""        # nf-oct-git_pull_request
IC_REVIEW=""    # nf-fa-eye
IC_CLOCK=""     # nf-fa-clock_o
IC_WARN=""      # nf-fa-warning
IC_CHECK=""     # nf-fa-check
IC_FIRE=""      # nf-fa-fire (using nf-md-fire)
IC_USER=""      # nf-fa-user
IC_CHART=""     # nf-fa-bar_chart
IC_JIRA=""      # nf-dev-jira
IC_BLOCK=""     # nf-fa-ban
IC_STAR=""      # nf-fa-star
IC_DASH=""      # nf-md-view_dashboard
IC_TREND=""     # nf-fa-line_chart

# ── Collect data ──────────────────────────────────────────────────────────────
if [[ -z "$GH_FILE" ]]; then
  GH_FILE="${TMPDIR}/dashboard-gh-$$.json"
  if [[ "$DRY_RUN" == "true" ]]; then
    bash "${SCRIPT_DIR}/metrics-github.sh" --dry-run --output "$GH_FILE"
  else
    bash "${SCRIPT_DIR}/metrics-github.sh" --output "$GH_FILE"
  fi
fi

if [[ -z "$JIRA_FILE" ]]; then
  JIRA_FILE="${TMPDIR}/dashboard-jira-$$.json"
  if [[ "$DRY_RUN" == "true" ]]; then
    bash "${SCRIPT_DIR}/metrics-jira.sh" --dry-run --output "$JIRA_FILE"
  else
    bash "${SCRIPT_DIR}/metrics-jira.sh" --output "$JIRA_FILE"
  fi
fi

GH=$(cat "$GH_FILE")
JR=$(cat "$JIRA_FILE")

# ── Drawing helpers ───────────────────────────────────────────────────────────
W=$TERM_WIDTH
INNER=$((W - 4))  # inside box borders + padding

# Box top
box_top() {
  printf "${CYN}┌"
  printf '%*s' "$((W-2))" '' | tr ' ' '─'
  printf "┐${RST}\n"
}

# Box bottom
box_bottom() {
  printf "${CYN}└"
  printf '%*s' "$((W-2))" '' | tr ' ' '─'
  printf "┘${RST}\n"
}

# Box separator
box_sep() {
  printf "${CYN}├"
  printf '%*s' "$((W-2))" '' | tr ' ' '─'
  printf "┤${RST}\n"
}

# Box line with content (handles ANSI escape width)
box_line() {
  local content="$1"
  # Strip ANSI for length calculation using python
  local stripped
  stripped=$(echo -e "$content" | strip_ansi)
  local len=${#stripped}
  local pad=$((INNER - len))
  [[ $pad -lt 0 ]] && pad=0
  printf "${CYN}│${RST} "
  printf "%b" "$content"
  printf '%*s' "$pad" ''
  printf " ${CYN}│${RST}\n"
}

# Box empty line
box_empty() {
  printf "${CYN}│${RST}"
  printf '%*s' "$((W-2))" ''
  printf "${CYN}│${RST}\n"
}

# Section title
section_title() {
  local icon="$1" title="$2" color="${3:-$BCYN}"
  box_sep
  box_line "${color}${BLD}${icon}  ${title}${RST}"
  box_empty
}

# Horizontal bar chart
bar() {
  local value="$1" max="$2" width="${3:-40}" color="${4:-$BGRN}"
  local fill=0
  if [[ "$max" -gt 0 ]]; then
    fill=$(( value * width / max ))
  fi
  [[ $fill -gt $width ]] && fill=$width
  local empty=$((width - fill))
  printf "${color}"
  printf '%*s' "$fill" '' | tr ' ' '━'
  printf "${DIM}"
  printf '%*s' "$empty" '' | tr ' ' '─'
  printf "${RST}"
}

# Color based on threshold (green=good, yellow=warn, red=bad)
threshold_color() {
  local value="$1" good="$2" warn="$3" invert="${4:-false}"
  local cmp
  if [[ "$invert" == "true" ]]; then
    cmp=$(calc "1 if float($value) <= float($good) else (2 if float($value) <= float($warn) else 3)")
  else
    cmp=$(calc "1 if float($value) >= float($good) else (2 if float($value) >= float($warn) else 3)")
  fi
  case "$cmp" in
    1) echo -ne "$BGRN" ;;
    2) echo -ne "$BYLW" ;;
    *) echo -ne "$BRED" ;;
  esac
}

# Right-align a number in N chars
rpad() {
  printf "%${2:-6}s" "$1"
}

# ── Extract data ──────────────────────────────────────────────────────────────
# GitHub
gh_total_opened=$(echo "$GH" | jq '.pr_stats.total_opened // 0')
gh_total_merged=$(echo "$GH" | jq '.pr_stats.total_merged // 0')
gh_total_open=$(echo "$GH" | jq '.pr_stats.total_open // 0')
gh_avg_merge=$(echo "$GH" | jq '.pr_stats.avg_time_to_merge_hours // 0')
gh_median_merge=$(echo "$GH" | jq '.pr_stats.median_time_to_merge_hours // 0')
gh_p95_merge=$(echo "$GH" | jq '.pr_stats.p95_time_to_merge_hours // 0')
gh_deploy_freq=$(echo "$GH" | jq '.dora.deployment_frequency_per_week // 0')
gh_period=$(echo "$GH" | jq -r '.meta.period_days // 30')
gh_is_dry=$(echo "$GH" | jq -r '.meta.dry_run // false')

# Jira
jr_wip_total=$(echo "$JR" | jq '.wip.total // 0')
jr_aging_count=$(echo "$JR" | jq '.aging.count // 0')
jr_blocked_count=$(echo "$JR" | jq '.blocked.count // 0')
jr_lead_avg=$(echo "$JR" | jq '.lead_time.avg_days // 0')
jr_lead_median=$(echo "$JR" | jq '.lead_time.median_days // 0')
jr_cycle_avg=$(echo "$JR" | jq '.cycle_time.avg_days // 0')
jr_cycle_median=$(echo "$JR" | jq '.cycle_time.median_days // 0')
jr_throughput_wk=$(echo "$JR" | jq '.dora.throughput_per_week // 0')
jr_is_dry=$(echo "$JR" | jq -r '.meta.dry_run // false')
jr_weeks=$(echo "$JR" | jq '.meta.period_weeks // 4')

# ── Render ────────────────────────────────────────────────────────────────────
clear 2>/dev/null || true
echo ""

box_top

# ── Header ────────────────────────────────────────────────────────────────────
generated=$(date '+%Y-%m-%d %H:%M')
dry_tag=""
[[ "$gh_is_dry" == "true" || "$jr_is_dry" == "true" ]] && dry_tag=" ${BYLW}[DRY RUN]${RST}"

box_line "${BLD}${BCYN}${IC_DASH}  Engineering Dashboard${RST}${dry_tag}"
box_line "${DIM}Generated: ${generated}  │  GitHub: ${gh_period}d  │  Jira: ${jr_weeks}w${RST}"

# ── Section: Delivery Overview ────────────────────────────────────────────────
section_title "$IC_CHART" "DELIVERY OVERVIEW" "$BBLU"

merge_rate=0
[[ "$gh_total_opened" -gt 0 ]] && merge_rate=$(calc "int($gh_total_merged * 100 / $gh_total_opened)")
merge_color=$(threshold_color "$merge_rate" 80 60)

box_line "  ${BLD}PRs Opened${RST}     $(rpad "$gh_total_opened" 4)    ${BLD}PRs Merged${RST}   $(rpad "$gh_total_merged" 4)    ${BLD}Open${RST}  $(rpad "$gh_total_open" 4)    ${BLD}Merge Rate${RST}  ${merge_color}${merge_rate}%${RST}"

# Throughput trend (Jira resolved per week)
box_empty
box_line "  ${BLD}${IC_TREND}  Weekly Throughput (Jira resolved)${RST}"

max_resolved=$(echo "$JR" | jq '[.resolved_per_week[]?.count // 0] | max // 1')
bar_width=$((INNER - 30))
[[ $bar_width -lt 20 ]] && bar_width=20
[[ $bar_width -gt 60 ]] && bar_width=60

while IFS= read -r week_line; do
  week=$(echo "$week_line" | jq -r '.week')
  count=$(echo "$week_line" | jq '.count')
  trend_color=$(threshold_color "$count" "$((max_resolved * 80 / 100))" "$((max_resolved * 50 / 100))")
  bar_str=$(bar "$count" "$max_resolved" "$bar_width" "$trend_color")
  box_line "  ${DIM}${week}${RST}  ${bar_str}  ${BLD}$(rpad "$count" 3)${RST}"
done < <(echo "$JR" | jq -c '.resolved_per_week[]?' 2>/dev/null)

box_line "  ${DIM}Avg throughput: ${jr_throughput_wk}/week  │  Deploy freq: ${gh_deploy_freq}/week${RST}"

# ── Section: Lead Time & Cycle Time ──────────────────────────────────────────
section_title "$IC_CLOCK" "LEAD TIME & CYCLE TIME" "$BMAG"

lead_color=$(threshold_color "$jr_lead_avg" 5 10 true)
cycle_color=$(threshold_color "$jr_cycle_avg" 3 5 true)
merge_h_color=$(threshold_color "$gh_avg_merge" 8 24 true)

box_line "  ${BLD}Lead Time${RST}  (created${DIM}${RST}resolved)          ${BLD}Cycle Time${RST}  (in-progress${DIM}${RST}done)"
box_line "  ${IC_CLOCK} Avg:    ${lead_color}${BLD}$(rpad "$jr_lead_avg" 5)d${RST}                    ${IC_CLOCK} Avg:    ${cycle_color}${BLD}$(rpad "$jr_cycle_avg" 5)d${RST}"
box_line "  ${IC_CLOCK} Median: $(rpad "$jr_lead_median" 5)d                    ${IC_CLOCK} Median: $(rpad "$jr_cycle_median" 5)d"
box_empty
box_line "  ${BLD}PR Merge Time${RST}  (opened${DIM}${RST}merged)"
box_line "  ${IC_CLOCK} Avg: ${merge_h_color}${BLD}$(rpad "$gh_avg_merge" 5)h${RST}   Median: $(rpad "$gh_median_merge" 5)h   P95: ${BYLW}$(rpad "$gh_p95_merge" 5)h${RST}"

# ── Section: GitHub Engagement Leaderboard ────────────────────────────────────
section_title "$IC_STAR" "GITHUB ENGAGEMENT LEADERBOARD" "$BYLW"

# Build sorted leaderboard
max_commits=$(echo "$GH" | jq '[.commits_by_author | to_entries[]? | .value.total] | max // 1')
commit_bar_width=$((INNER - 65))
[[ $commit_bar_width -lt 10 ]] && commit_bar_width=10
[[ $commit_bar_width -gt 40 ]] && commit_bar_width=40

header_fmt="  ${BLD}%-14s %7s %6s %6s %6s${RST}  %-${commit_bar_width}s"
box_line "$(printf "$header_fmt" "Developer" "Commits" "PRs" "Merged" "Reviews" "Activity")"
box_line "  $(printf '%*s' "$((INNER - 4))" '' | tr ' ' '╌')"

# Sort by total commits descending
while IFS= read -r entry; do
  author=$(echo "$entry" | jq -r '.key')
  commits=$(echo "$entry" | jq '.commits')
  opened=$(echo "$GH" | jq --arg a "$author" '.prs_by_author[$a].opened // 0')
  merged=$(echo "$GH" | jq --arg a "$author" '.prs_by_author[$a].merged // 0')
  reviews=$(echo "$GH" | jq --arg a "$author" '.prs_by_author[$a].reviews_given // 0')

  # Truncate author name
  disp_author="${author:0:14}"

  # Score-based coloring
  score=$((commits + opened * 3 + reviews * 2))
  if [[ $score -gt 50 ]]; then
    row_color="$BGRN"
  elif [[ $score -gt 20 ]]; then
    row_color="$BYLW"
  else
    row_color="$BRED"
  fi

  bar_str=$(bar "$commits" "$max_commits" "$commit_bar_width" "$row_color")
  row_fmt="  ${row_color}%-14s${RST} %7s %6s %6s %6s  %s"
  box_line "$(printf "$row_fmt" "$disp_author" "$commits" "$opened" "$merged" "$reviews" "$bar_str")"
done < <(echo "$GH" | jq -c '[.commits_by_author | to_entries[] | {key: .key, commits: .value.total}] | sort_by(-.commits) | .[]' 2>/dev/null)

# ── Section: Low Engagement Alert ─────────────────────────────────────────────
low_count=$(echo "$GH" | jq '.low_engagement | length')
if [[ "$low_count" -gt 0 ]]; then
  section_title "$IC_WARN" "LOW ENGAGEMENT ALERT" "$BRED"

  while IFS= read -r entry; do
    author=$(echo "$entry" | jq -r '.author')
    commits=$(echo "$entry" | jq '.commits')
    prs=$(echo "$entry" | jq '.prs_opened')
    reviews=$(echo "$entry" | jq '.reviews_given')
    reason=$(echo "$entry" | jq -r '.reason')
    box_line "  ${BRED}${IC_WARN}${RST}  ${BLD}${author}${RST}  │  commits: ${BRED}${commits}${RST}  prs: ${BRED}${prs}${RST}  reviews: ${BRED}${reviews}${RST}"
    box_line "     ${DIM}${reason}${RST}"
  done < <(echo "$GH" | jq -c '.low_engagement[]?' 2>/dev/null)
fi

# ── Section: WIP Health ───────────────────────────────────────────────────────
section_title "$IC_FIRE" "WIP HEALTH" "$BYLW"

wip_color=$(threshold_color "$jr_wip_total" 10 20 true)
aging_color=$(threshold_color "$jr_aging_count" 2 5 true)
blocked_color=$(threshold_color "$jr_blocked_count" 1 3 true)

box_line "  ${BLD}In Progress${RST}  ${wip_color}${BLD}$(rpad "$jr_wip_total" 3)${RST}     ${BLD}Aging (>7d)${RST}  ${aging_color}${BLD}$(rpad "$jr_aging_count" 3)${RST}     ${BLD}${IC_BLOCK} Blocked${RST}  ${blocked_color}${BLD}$(rpad "$jr_blocked_count" 3)${RST}"

# WIP by project
box_empty
box_line "  ${BLD}WIP by Project${RST}"
max_wip_proj=$(echo "$JR" | jq '[.wip.by_project | to_entries[]? | .value] | max // 1')
wip_bar_width=$((INNER - 25))
[[ $wip_bar_width -lt 10 ]] && wip_bar_width=10
[[ $wip_bar_width -gt 50 ]] && wip_bar_width=50

while IFS= read -r entry; do
  proj=$(echo "$entry" | jq -r '.key')
  count=$(echo "$entry" | jq '.value')
  pc=$(threshold_color "$count" 3 6 true)
  bar_str=$(bar "$count" "$max_wip_proj" "$wip_bar_width" "$pc")
  box_line "  $(printf '%-8s' "$proj")  ${bar_str}  ${BLD}$(rpad "$count" 3)${RST}"
done < <(echo "$JR" | jq -c '.wip.by_project | to_entries | sort_by(-.value) | .[]' 2>/dev/null)

# Aging items detail
if [[ "$jr_aging_count" -gt 0 ]]; then
  box_empty
  box_line "  ${BLD}${IC_CLOCK} Aging Issues (>7 days in progress)${RST}"
  box_line "  $(printf '%*s' "$((INNER - 4))" '' | tr ' ' '╌')"

  while IFS= read -r entry; do
    key=$(echo "$entry" | jq -r '.key')
    summary=$(echo "$entry" | jq -r '.summary')
    assignee=$(echo "$entry" | jq -r '.assignee')
    days=$(echo "$entry" | jq '.days_in_progress')
    priority=$(echo "$entry" | jq -r '.priority')

    # Truncate summary
    max_sum=$((INNER - 55))
    [[ ${#summary} -gt $max_sum ]] && summary="${summary:0:$max_sum}.."

    days_color=$(threshold_color "$days" 7 14 true)
    prio_color="$WHT"
    [[ "$priority" == "Critical" || "$priority" == "Highest" ]] && prio_color="$BRED"
    [[ "$priority" == "High" ]] && prio_color="$BYLW"

    box_line "  ${prio_color}${key}${RST}  ${days_color}${BLD}${days}d${RST}  ${DIM}${assignee}${RST}  ${summary}"
  done < <(echo "$JR" | jq -c '.aging.issues_over_7_days[]?' 2>/dev/null)
fi

# Blocked items detail
if [[ "$jr_blocked_count" -gt 0 ]]; then
  box_empty
  box_line "  ${BLD}${IC_BLOCK} Blocked Items${RST}"
  box_line "  $(printf '%*s' "$((INNER - 4))" '' | tr ' ' '╌')"

  while IFS= read -r entry; do
    key=$(echo "$entry" | jq -r '.key')
    summary=$(echo "$entry" | jq -r '.summary')
    assignee=$(echo "$entry" | jq -r '.assignee')
    days=$(echo "$entry" | jq '.blocked_days')

    max_sum=$((INNER - 45))
    [[ ${#summary} -gt $max_sum ]] && summary="${summary:0:$max_sum}.."

    box_line "  ${BRED}${IC_BLOCK} ${key}${RST}  ${BLD}${days}d${RST}  ${DIM}${assignee}${RST}  ${summary}"
  done < <(echo "$JR" | jq -c '.blocked.items[]?' 2>/dev/null)
fi

# ── Section: Repo Activity ────────────────────────────────────────────────────
section_title "$IC_GIT" "REPO ACTIVITY" "$BGRN"

max_repo_commits=$(echo "$GH" | jq '[.repos_summary | to_entries[]? | .value.commits] | max // 1')
repo_bar_width=$((INNER - 42))
[[ $repo_bar_width -lt 10 ]] && repo_bar_width=10
[[ $repo_bar_width -gt 45 ]] && repo_bar_width=45

box_line "  $(printf "${BLD}%-20s %7s %6s %5s${RST}" 'Repository' 'Commits' 'PRs' 'Devs')  Activity"
box_line "  $(printf '%*s' "$((INNER - 4))" '' | tr ' ' '╌')"

while IFS= read -r entry; do
  repo=$(echo "$entry" | jq -r '.key')
  commits=$(echo "$entry" | jq '.value.commits')
  prs=$(echo "$entry" | jq '.value.prs_merged')
  contribs=$(echo "$entry" | jq '.value.contributors')

  rc=$(threshold_color "$commits" 20 5)
  bar_str=$(bar "$commits" "$max_repo_commits" "$repo_bar_width" "$rc")
  box_line "  $(printf '%-20s' "${repo:0:20}") $(rpad "$commits" 7) $(rpad "$prs" 6) $(rpad "$contribs" 5)  ${bar_str}"
done < <(echo "$GH" | jq -c '.repos_summary | to_entries | sort_by(-.value.commits) | .[]' 2>/dev/null)

# ── Section: DORA Metrics Summary ─────────────────────────────────────────────
section_title "$IC_DASH" "DORA-LIKE METRICS SUMMARY" "$BCYN"

deploy_color=$(threshold_color "$gh_deploy_freq" 5 2)
lead_dora_color=$(threshold_color "$jr_lead_avg" 5 14 true)
cycle_dora_color=$(threshold_color "$jr_cycle_avg" 2 5 true)

box_line "  ${BLD}Deployment Frequency${RST}     ${deploy_color}${BLD}$(rpad "$gh_deploy_freq" 6)/week${RST}     ${DIM}(PRs merged to main per week)${RST}"
box_line "  ${BLD}Lead Time for Changes${RST}    ${lead_dora_color}${BLD}$(rpad "$jr_lead_avg" 6)days${RST}      ${DIM}(created to resolved avg)${RST}"
box_line "  ${BLD}Cycle Time${RST}               ${cycle_dora_color}${BLD}$(rpad "$jr_cycle_avg" 6)days${RST}      ${DIM}(in-progress to done avg)${RST}"
box_line "  ${BLD}PR Merge Time${RST}            ${merge_h_color}${BLD}$(rpad "$gh_avg_merge" 6)hours${RST}     ${DIM}(opened to merged avg)${RST}"

box_empty
box_bottom
echo ""

# ── Cleanup temp files ────────────────────────────────────────────────────────
[[ -f "${TMPDIR}/dashboard-gh-$$.json" ]] && rm -f "${TMPDIR}/dashboard-gh-$$.json"
[[ -f "${TMPDIR}/dashboard-jira-$$.json" ]] && rm -f "${TMPDIR}/dashboard-jira-$$.json"
