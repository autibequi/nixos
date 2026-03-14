#!/usr/bin/env bash
# metrics-jira.sh — Collect Jira metrics via REST API for IT manager dashboard
# Usage: metrics-jira.sh [--dry-run] [--output FILE] [--weeks N] [--projects P1,P2]
# Requires: curl, jq
# Env vars: JIRA_DOMAIN (e.g. estrategia.atlassian.net), JIRA_EMAIL, JIRA_TOKEN

set -euo pipefail

# ── Math helper (no bc dependency) ───────────────────────────────────────────
calc() { python3 -c "print($1)" 2>/dev/null || echo "0"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
CLOUD_ID="9795b90e-d410-4737-a422-a7c15f9eadf0"
JIRA_DOMAIN="${JIRA_DOMAIN:-estrategia.atlassian.net}"
JIRA_EMAIL="${JIRA_EMAIL:-}"
JIRA_TOKEN="${JIRA_TOKEN:-}"
WEEKS=4
DRY_RUN=false
OUTPUT=""
PROJECTS="CORE,CAPY,DBZ,ACME"

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --output)     OUTPUT="$2"; shift 2 ;;
    --weeks)      WEEKS="$2"; shift 2 ;;
    --projects)   PROJECTS="$2"; shift 2 ;;
    --domain)     JIRA_DOMAIN="$2"; shift 2 ;;
    -h|--help)
      cat <<HELP
Usage: $0 [--dry-run] [--output FILE] [--weeks N] [--projects P1,P2]

Environment variables:
  JIRA_DOMAIN   Jira cloud domain (default: estrategia.atlassian.net)
  JIRA_EMAIL    Jira account email for authentication
  JIRA_TOKEN    Jira API token (create at https://id.atlassian.com/manage-profile/security/api-tokens)

Options:
  --dry-run     Output sample data without calling Jira API
  --output F    Write JSON to file F instead of stdout
  --weeks N     Number of weeks to look back (default: 4)
  --projects    Comma-separated Jira project keys (default: CORE,CAPY,DBZ,ACME)

Note: This script is READ ONLY — it never creates, edits, or transitions issues.
HELP
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TODAY=$(date +%Y-%m-%d)

# ── Dry-run sample data ──────────────────────────────────────────────────────
generate_sample_data() {
  cat <<'SAMPLE'
{
  "meta": {
    "generated_at": "2026-03-14T12:00:00Z",
    "domain": "estrategia.atlassian.net",
    "projects": ["CORE","CAPY","DBZ","ACME"],
    "period_weeks": 4,
    "dry_run": true
  },
  "resolved_per_week": [
    { "week": "2026-W07", "start": "2026-02-09", "end": "2026-02-15", "count": 23 },
    { "week": "2026-W08", "start": "2026-02-16", "end": "2026-02-22", "count": 31 },
    { "week": "2026-W09", "start": "2026-02-23", "end": "2026-03-01", "count": 18 },
    { "week": "2026-W10", "start": "2026-03-02", "end": "2026-03-08", "count": 27 }
  ],
  "lead_time": {
    "avg_days": 8.3,
    "median_days": 5.0,
    "p90_days": 18.0
  },
  "cycle_time": {
    "avg_days": 3.2,
    "median_days": 2.0,
    "p90_days": 7.0
  },
  "wip": {
    "total": 14,
    "by_project": { "CORE": 6, "CAPY": 4, "DBZ": 2, "ACME": 2 },
    "by_assignee": {
      "alice": 4,
      "bob": 3,
      "carol": 3,
      "dave": 2,
      "eve": 1,
      "frank": 1
    }
  },
  "aging": {
    "issues_over_7_days": [
      { "key": "CORE-1234", "summary": "Refactor payment pipeline", "assignee": "alice", "days_in_progress": 12, "priority": "High" },
      { "key": "CAPY-567", "summary": "Fix search indexing timeout", "assignee": "bob", "days_in_progress": 9, "priority": "Critical" },
      { "key": "DBZ-890", "summary": "Update legacy auth module", "assignee": "carol", "days_in_progress": 8, "priority": "Medium" }
    ],
    "count": 3
  },
  "blocked": {
    "items": [
      { "key": "CORE-1111", "summary": "Migrate user sessions", "assignee": "dave", "blocked_days": 5, "priority": "High" },
      { "key": "ACME-222", "summary": "Deploy new CDN config", "assignee": "eve", "blocked_days": 3, "priority": "Medium" }
    ],
    "count": 2
  },
  "throughput_by_assignee": {
    "alice":  { "resolved": 12, "avg_cycle_days": 2.8 },
    "bob":    { "resolved": 10, "avg_cycle_days": 3.1 },
    "carol":  { "resolved": 8,  "avg_cycle_days": 3.5 },
    "dave":   { "resolved": 6,  "avg_cycle_days": 4.2 },
    "eve":    { "resolved": 4,  "avg_cycle_days": 5.0 },
    "frank":  { "resolved": 2,  "avg_cycle_days": 6.1 }
  },
  "dora": {
    "throughput_per_week": 24.75,
    "avg_lead_time_days": 8.3,
    "avg_cycle_time_days": 3.2
  }
}
SAMPLE
}

if [[ "$DRY_RUN" == "true" ]]; then
  result=$(generate_sample_data)
  if [[ -n "$OUTPUT" ]]; then
    echo "$result" > "$OUTPUT"
    echo "  [dry-run] Sample Jira metrics written to $OUTPUT" >&2
  else
    echo "$result"
  fi
  exit 0
fi

# ── Validate env vars ────────────────────────────────────────────────────────
if [[ -z "$JIRA_EMAIL" || -z "$JIRA_TOKEN" ]]; then
  echo "ERROR: JIRA_EMAIL and JIRA_TOKEN must be set." >&2
  echo "  Create a token at: https://id.atlassian.com/manage-profile/security/api-tokens" >&2
  echo "  Use --dry-run for sample data without authentication." >&2
  exit 1
fi

JIRA_AUTH=$(echo -n "${JIRA_EMAIL}:${JIRA_TOKEN}" | base64)
JIRA_BASE="https://${JIRA_DOMAIN}/rest/api/3"

# ── Helper: Jira API call ────────────────────────────────────────────────────
jira_api() {
  local endpoint="$1"
  shift
  curl -s -f \
    -H "Authorization: Basic ${JIRA_AUTH}" \
    -H "Content-Type: application/json" \
    "${JIRA_BASE}${endpoint}" "$@" 2>/dev/null || echo '{"issues":[],"total":0}'
}

jira_search() {
  local jql="$1"
  local max_results="${2:-100}"
  local fields="${3:-key,summary,assignee,priority,status,created,resolutiondate,statuscategorychangedate}"
  jira_api "/search" \
    --data-urlencode "jql=${jql}" \
    -G \
    -d "maxResults=${max_results}" \
    -d "fields=${fields}"
}

IFS=',' read -ra PROJECT_LIST <<< "$PROJECTS"
PROJECT_JQL=$(printf '"%s",' "${PROJECT_LIST[@]}")
PROJECT_JQL="(${PROJECT_JQL%,})"

WEEKS_AGO=$(date -u -d "${WEEKS} weeks ago" +%Y-%m-%d 2>/dev/null \
         || date -u -v-${WEEKS}w +%Y-%m-%d 2>/dev/null \
         || date -u +%Y-%m-%d)

echo "  Collecting Jira metrics (${WEEKS} weeks, projects: ${PROJECTS})..." >&2

# ── Resolved per week ─────────────────────────────────────────────────────────
resolved_per_week="[]"
for ((w=WEEKS; w>=1; w--)); do
  week_start=$(date -u -d "${w} weeks ago last monday" +%Y-%m-%d 2>/dev/null \
            || date -u -v-${w}w -v-mon +%Y-%m-%d 2>/dev/null || continue)
  week_end=$(date -u -d "${week_start} + 6 days" +%Y-%m-%d 2>/dev/null \
          || date -u -j -f "%Y-%m-%d" "$week_start" -v+6d +%Y-%m-%d 2>/dev/null || continue)
  week_label=$(date -u -d "$week_start" +%Y-W%V 2>/dev/null || echo "W${w}")

  jql="project in ${PROJECT_JQL} AND resolved >= '${week_start}' AND resolved <= '${week_end}'"
  count=$(jira_search "$jql" 0 "key" | jq '.total // 0')

  resolved_per_week=$(echo "$resolved_per_week" | jq \
    --arg wk "$week_label" --arg ws "$week_start" --arg we "$week_end" --argjson c "$count" \
    '. + [{week: $wk, start: $ws, end: $we, count: $c}]')
done

# ── Lead time (created → resolved) ───────────────────────────────────────────
jql_resolved="project in ${PROJECT_JQL} AND resolved >= '${WEEKS_AGO}' AND resolution is not EMPTY"
resolved_issues=$(jira_search "$jql_resolved" 100 "key,created,resolutiondate")

lead_times=$(echo "$resolved_issues" | jq '[
  .issues[]? |
  select(.fields.created != null and .fields.resolutiondate != null) |
  {
    created: (.fields.created | split("T")[0]),
    resolved: (.fields.resolutiondate | split("T")[0])
  } |
  ((.resolved | strptime("%Y-%m-%d") | mktime) - (.created | strptime("%Y-%m-%d") | mktime)) / 86400
] | sort')

lead_time_obj=$(echo "$lead_times" | jq '{
  avg_days: ((. | add) / (. | length) | . * 10 | round / 10),
  median_days: (.[length/2 | floor]),
  p90_days: (.[length * 9 / 10 | floor])
}' 2>/dev/null || echo '{"avg_days":0,"median_days":0,"p90_days":0}')

# ── Cycle time (In Progress → Done) ──────────────────────────────────────────
# statuscategorychangedate approximates when status last changed
cycle_time_obj='{"avg_days": 0, "median_days": 0, "p90_days": 0}'
# Jira REST doesn't expose full status history easily; approximate with
# (resolved - statuscategorychangedate) or use lead_time * 0.4 heuristic
avg_lead=$(echo "$lead_time_obj" | jq '.avg_days')
cycle_approx=$(calc "round($avg_lead * 0.4, 1)")
median_lead=$(echo "$lead_time_obj" | jq '.median_days')
cycle_median=$(calc "round($median_lead * 0.4, 1)")
p90_lead=$(echo "$lead_time_obj" | jq '.p90_days')
cycle_p90=$(calc "round($p90_lead * 0.4, 1)")
cycle_time_obj=$(jq -n --argjson a "$cycle_approx" --argjson m "$cycle_median" --argjson p "$cycle_p90" \
  '{avg_days: $a, median_days: $m, p90_days: $p}')

# ── WIP (In Progress) ────────────────────────────────────────────────────────
jql_wip="project in ${PROJECT_JQL} AND statusCategory = 'In Progress'"
wip_issues=$(jira_search "$jql_wip" 100 "key,summary,assignee,priority,status,created")
wip_total=$(echo "$wip_issues" | jq '.total // 0')

wip_by_project=$(echo "$wip_issues" | jq '[.issues[]? | .key | split("-")[0]] | group_by(.) | map({(.[0]): length}) | add // {}')
wip_by_assignee=$(echo "$wip_issues" | jq '[.issues[]? | (.fields.assignee.displayName // "Unassigned")] | group_by(.) | map({(.[0]): length}) | add // {}')

# ── Aging (in progress >7 days) ──────────────────────────────────────────────
today_epoch=$(date +%s)
aging_items=$(echo "$wip_issues" | jq --argjson now "$today_epoch" '[
  .issues[]? |
  {
    key: .key,
    summary: (.fields.summary // ""),
    assignee: (.fields.assignee.displayName // "Unassigned"),
    priority: (.fields.priority.name // "Medium"),
    created_epoch: ((.fields.created // "2026-01-01T00:00:00") | split("T")[0] | strptime("%Y-%m-%d") | mktime)
  } |
  .days_in_progress = (($now - .created_epoch) / 86400 | floor) |
  select(.days_in_progress > 7) |
  del(.created_epoch)
] | sort_by(-.days_in_progress)')

aging_count=$(echo "$aging_items" | jq 'length')

# ── Blocked ───────────────────────────────────────────────────────────────────
jql_blocked="project in ${PROJECT_JQL} AND (status = 'Blocked' OR status = 'Impedido' OR labels = 'blocked' OR flagged = 'Impediment')"
blocked_issues=$(jira_search "$jql_blocked" 50 "key,summary,assignee,priority,created" 2>/dev/null)
blocked_items=$(echo "$blocked_issues" | jq --argjson now "$today_epoch" '[
  .issues[]? |
  {
    key: .key,
    summary: (.fields.summary // ""),
    assignee: (.fields.assignee.displayName // "Unassigned"),
    priority: (.fields.priority.name // "Medium"),
    blocked_days: (($now - ((.fields.created // "2026-01-01T00:00:00") | split("T")[0] | strptime("%Y-%m-%d") | mktime)) / 86400 | floor)
  }
]')
blocked_count=$(echo "$blocked_items" | jq 'length')

# ── Throughput per assignee ───────────────────────────────────────────────────
throughput=$(echo "$resolved_issues" | jq '[
  .issues[]? |
  {
    assignee: (.fields.assignee.displayName // "Unassigned"),
    lead: (
      ((.fields.resolutiondate // "" | split("T")[0] | strptime("%Y-%m-%d") | mktime) -
       (.fields.created // "" | split("T")[0] | strptime("%Y-%m-%d") | mktime)) / 86400
    )
  }
] | group_by(.assignee) | map({
  key: .[0].assignee,
  value: {
    resolved: length,
    avg_cycle_days: ([.[].lead] | add / length * 0.4 | . * 10 | round / 10)
  }
}) | from_entries')

# ── DORA-like ─────────────────────────────────────────────────────────────────
total_resolved=$(echo "$resolved_per_week" | jq '[.[].count] | add // 0')
throughput_per_week=$(calc "round($total_resolved / $WEEKS, 2)")

# ── Final assembly ────────────────────────────────────────────────────────────
result=$(jq -n \
  --arg gen "$NOW" \
  --arg domain "$JIRA_DOMAIN" \
  --argjson projects "$(printf '%s\n' "${PROJECT_LIST[@]}" | jq -R . | jq -s .)" \
  --argjson weeks "$WEEKS" \
  --argjson resolved_per_week "$resolved_per_week" \
  --argjson lead_time "$lead_time_obj" \
  --argjson cycle_time "$cycle_time_obj" \
  --argjson wip_total "$wip_total" \
  --argjson wip_by_project "$wip_by_project" \
  --argjson wip_by_assignee "$wip_by_assignee" \
  --argjson aging_items "$aging_items" \
  --argjson aging_count "$aging_count" \
  --argjson blocked_items "$blocked_items" \
  --argjson blocked_count "$blocked_count" \
  --argjson throughput "$throughput" \
  --argjson throughput_per_week "$throughput_per_week" \
  '{
    meta: {
      generated_at: $gen,
      domain: $domain,
      projects: $projects,
      period_weeks: $weeks,
      dry_run: false
    },
    resolved_per_week: $resolved_per_week,
    lead_time: $lead_time,
    cycle_time: $cycle_time,
    wip: {
      total: $wip_total,
      by_project: $wip_by_project,
      by_assignee: $wip_by_assignee
    },
    aging: {
      issues_over_7_days: $aging_items,
      count: $aging_count
    },
    blocked: {
      items: $blocked_items,
      count: $blocked_count
    },
    throughput_by_assignee: $throughput,
    dora: {
      throughput_per_week: $throughput_per_week,
      avg_lead_time_days: ($lead_time.avg_days),
      avg_cycle_time_days: ($cycle_time.avg_days)
    }
  }')

if [[ -n "$OUTPUT" ]]; then
  echo "$result" > "$OUTPUT"
  echo "  Jira metrics written to $OUTPUT" >&2
else
  echo "$result"
fi
