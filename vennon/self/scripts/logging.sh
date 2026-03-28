#!/usr/bin/env bash
# scripts/logging.sh — structured logging with prefix + color
# Source this file: source "$(dirname "$0")/logging.sh"
# Requires colors.sh (auto-sourced if not loaded)

[[ "${_LIB_LOGGING_LOADED:-}" == "1" ]] && return 0
_LIB_LOGGING_LOADED=1

_LOGGING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_LOGGING_DIR}/colors.sh"

# log_info <prefix> <message>
log_info() {
  local prefix="${1:-}" msg="${2:-}"
  echo -e "${CYAN}[${prefix}]${R} ${msg}"
}

# log_warn <prefix> <message>
log_warn() {
  local prefix="${1:-}" msg="${2:-}"
  echo -e "${YELLOW}[${prefix}]${R} ${msg}" >&2
}

# log_error <prefix> <message>
log_error() {
  local prefix="${1:-}" msg="${2:-}"
  echo -e "${RED}[${prefix}]${R} ${msg}" >&2
}

# log_success <message>
log_success() {
  local msg="${1:-}"
  echo -e "${GREEN}✓${R} ${msg}"
}

# log_debug <prefix> <message> — only if DEBUG=1
log_debug() {
  [[ "${DEBUG:-0}" != "1" ]] && return 0
  local prefix="${1:-}" msg="${2:-}"
  echo -e "${DIM}[${prefix}] ${msg}${R}" >&2
}

# log_step <n> <total> <message> — progress indicator
log_step() {
  local n="$1" total="$2" msg="$3"
  echo -e "${DIM}(${n}/${total})${R} ${msg}"
}
