#!/usr/bin/env bash
# lib/colors.sh — ANSI color definitions, single source of truth
# Source this file in any script: source "$(dirname "$0")/../lib/colors.sh"
# Supports NO_COLOR env var: https://no-color.org/

# Guard against double-sourcing
[[ "${_LIB_COLORS_LOADED:-}" == "1" ]] && return 0
_LIB_COLORS_LOADED=1

if [[ "${NO_COLOR:-}" == "1" || ! -t 1 ]]; then
  # No color mode
  R=""    B=""    DIM=""   ITALIC=""
  RED=""  GREEN=""  YELLOW=""  BLUE=""  CYAN=""  MAGENTA=""  WHITE=""  ORANGE=""
  BRED="" BGREEN="" BYELLOW="" BBLUE="" BCYAN="" BMAGENTA=""
  BG_RED="" BG_GREEN="" BG_YELLOW="" BG_BLUE=""
else
  # Reset & modifiers
  R='\033[0m'
  B='\033[1m'
  DIM='\033[2m'
  ITALIC='\033[3m'

  # Standard colors
  RED='\033[31m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  BLUE='\033[38;5;33m'
  CYAN='\033[36m'
  MAGENTA='\033[35m'
  WHITE='\033[97m'
  ORANGE='\033[38;5;208m'

  # Bright variants
  BRED='\033[91m'
  BGREEN='\033[92m'
  BYELLOW='\033[93m'
  BBLUE='\033[94m'
  BCYAN='\033[96m'
  BMAGENTA='\033[95m'

  # Backgrounds
  BG_RED='\033[41m'
  BG_GREEN='\033[42m'
  BG_YELLOW='\033[43m'
  BG_BLUE='\033[44m'
fi

export R B DIM ITALIC
export RED GREEN YELLOW BLUE CYAN MAGENTA WHITE ORANGE
export BRED BGREEN BYELLOW BBLUE BCYAN BMAGENTA
export BG_RED BG_GREEN BG_YELLOW BG_BLUE
