#!/usr/bin/env bash
# modules.sh — bootstrap orchestrator: colors, helpers, then dashboard modules

# ── Colors (coral theme — matching Claude mascot) ────────────────────────────
R=$'\033[0m' B=$'\033[1m' DIM=$'\033[2m'
P_GREEN=$'\033[1;38;5;174m'  P_AMBER=$'\033[1;93m'
P_CYAN=$'\033[1;38;5;210m'   P_MAGENTA=$'\033[1;38;5;204m'
P_RED=$'\033[1;91m'          P_DIM=$'\033[2;38;5;210m'
ON=$'\033[1;32m'             OFF=$'\033[1;31m'
# Fallback 256
CYAN=$'\033[38;5;210m' GREEN=$'\033[38;5;174m' YELLOW=$'\033[33m' RED=$'\033[31m'
ORANGE=$'\033[38;5;208m' BLUE=$'\033[38;5;33m' WHITE=$'\033[97m'
MAGENTA=$'\033[38;5;204m' GRAY=$'\033[38;5;245m'

# ── Globals ───────────────────────────────────────────────────────────────────
# Detect container once — sets IS_CONTAINER and WS
# IS_CONTAINER=1 → dentro do container claude-nix-sandbox
# IS_CONTAINER=0 → no host NixOS diretamente
if [[ "${CLAUDE_ENV:-}" == "container" ]] || [[ -f "/.dockerenv" ]] || grep -q 'docker\|container' /proc/1/cgroup 2>/dev/null; then
  IS_CONTAINER=1
  WS="/workspace"
else
  IS_CONTAINER=0
  _mdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  WS="$(cd "$_mdir/../.." && pwd)"
fi
KANBAN="$WS/obsidian/kanban.md"
SCHEDULED="$WS/obsidian/_agent/scheduled.md"
TODAY=$(date +%Y-%m-%d)
now=$(date +%s)
COLS="${COLUMNS:-$(tput cols 2>/dev/null || echo 100)}"
LINS="${LINES:-$(tput lines 2>/dev/null || echo 30)}"
BOOTSTRAP_BANNER="${BOOTSTRAP_BANNER:-auto}"
[[ "$BOOTSTRAP_BANNER" == "auto" ]] && {
  [[ "$COLS" -lt 90 || "$LINS" -lt 22 ]] && BOOTSTRAP_BANNER="compact" || BOOTSTRAP_BANNER="full"
}
AUTOJARVIS_FLAG="$WS/.ephemeral/auto-jarvis"
USAGE_BAR_FILE="$WS/.ephemeral/usage-bar.txt"

# ── Helpers ───────────────────────────────────────────────────────────────────
fmt_age() {
  local s="$1" h=$(( $1 / 3600 )) m=$(( ($1 % 3600) / 60 ))
  [[ $h -gt 0 ]] && echo "${h}h${m}m" || echo "${m}m"
}

find_latest_log() {
  local clock="$1" best="" best_mod=0
  [[ -f "$WS/.ephemeral/logs/worker-${clock}.log" ]] && {
    best="$WS/.ephemeral/logs/worker-${clock}.log"
    best_mod=$(stat -c %Y "$best" 2>/dev/null || echo 0)
  }
  local legacy; legacy=$(ls -t "$WS"/logs/*.log 2>/dev/null | head -1)
  if [[ -n "${legacy:-}" ]]; then
    local lmod; lmod=$(stat -c %Y "$legacy" 2>/dev/null || echo 0)
    [[ "$lmod" -gt "$best_mod" ]] && { best="$legacy"; best_mod="$lmod"; }
  fi
  echo "$best_mod:$best"
}

# Clickable link helper (OSC 8) — only if terminal supports it
# Usage: osc8_link <url> <visible_text>
osc8_link() {
  local url="$1" text="$2"
  # Claude Code terminal doesn't support OSC 8 — just print text
  if [[ -n "${CLAUDE_CODE:-}" || -n "${TERM_PROGRAM_VERSION:-}" ]]; then
    printf '%s' "$text"
  else
    printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
  fi
}

# ── Export for submodules ─────────────────────────────────────────────────────
export WS KANBAN SCHEDULED TODAY now COLS LINS BOOTSTRAP_BANNER AUTOJARVIS_FLAG IS_CONTAINER

# ── Source dashboard modules ──────────────────────────────────────────────────
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BOOTSTRAP_DIR/tree.dashboard.sh"       || echo -e "${P_RED}  ✗ tree load failed${R}"
source "$BOOTSTRAP_DIR/header.dashboard.sh"     || echo -e "${P_RED}  ✗ header load failed${R}"
source "$BOOTSTRAP_DIR/scheduler.dashboard.sh"  || echo -e "${P_RED}  ✗ scheduler load failed${R}"
source "$BOOTSTRAP_DIR/github.dashboard.sh"     || echo -e "${P_RED}  ✗ github load failed${R}"
source "$BOOTSTRAP_DIR/rss.dashboard.sh"        || echo -e "${P_RED}  ✗ rss load failed${R}"

# ── Footer ────────────────────────────────────────────────────────────────────
echo -e "${P_DIM}$(printf '─%.0s' $(seq 1 80))${R}"
