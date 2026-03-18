#!/usr/bin/env bash
# usage-bar.sh — Gera barra de uso para bootstrap/status.
# 0) OAuth Claude (principal): claude-oauth-usage.sh (sem chave externa).
# 1) Cursor /usage — não implementado (legado, exige CURSOR_API_KEY Enterprise).
# 2) Anthropic Admin — não implementado (legado, exige ANTHROPIC_ADMIN_KEY).
# Escreve em .ephemeral/usage-bar.txt (linha 1 machine-readable, linha 2 humana).
# Uso: source ou bash; export WS=/workspace.
set -euo pipefail

WS="${WS:-/workspace}"
OUT_FILE="${OUT_FILE:-$WS/.ephemeral/usage-bar.txt}"
PERIOD="${USAGE_BAR_PERIOD:-30d}"
BAR_WIDTH=22

mkdir -p "$(dirname "$OUT_FILE")"

R='\033[0m' B='\033[1m' DIM='\033[2m'
GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m'
[[ ! -t 1 ]] && R="" B="" DIM="" GREEN="" YELLOW="" RED=""

bar() {
  local value="$1" max="$2" width="${3:-20}" color="$4"
  local fill=0
  if [[ "${max:-0}" -gt 0 ]]; then fill=$(( value * width / max )); fi
  [[ $fill -gt $width ]] && fill=$width
  local empty=$(( width - fill ))
  printf '%b' "$color"
  printf '%*s' "$fill" '' | tr ' ' '━'
  printf '%b' "$DIM"
  printf '%*s' "$empty" '' | tr ' ' '─'
  printf '%b' "$R"
}

bar_color() {
  local pct="$1"
  if [[ "$pct" -lt 60 ]]; then echo -ne "$GREEN"
  elif [[ "$pct" -lt 85 ]]; then echo -ne "$YELLOW"
  else echo -ne "$RED"; fi
}

write_fallback() {
  local err="$1" msg="$2"
  echo "used=0 max=0 pct=0 period=$PERIOD updated=$(date -u +%Y-%m-%dT%H:%M:%SZ) error=$err" > "$OUT_FILE"
  echo -e "${DIM}${msg}${R}" >> "$OUT_FILE"
}

# --- Fonte 0: claude-oauth-usage.sh (OAuth token — sem chave externa) ---
OAUTH_SCRIPT=""
for _p in "$WS/zion/scripts/claude-oauth-usage.sh" "/workspace/zion/scripts/claude-oauth-usage.sh"; do
  [[ -x "$_p" ]] && OAUTH_SCRIPT="$_p" && break
done

if [[ -n "$OAUTH_SCRIPT" ]] && command -v jq &>/dev/null; then
  OAUTH_JSON=$("$OAUTH_SCRIPT" 2>/dev/null) || true
  if [[ -n "$OAUTH_JSON" ]] && echo "$OAUTH_JSON" | jq -e '.five_hour' &>/dev/null; then
    FH_PCT=$(echo "$OAUTH_JSON" | jq -r '(.five_hour?.utilization? // 0) | floor')
    SD_PCT=$(echo "$OAUTH_JSON" | jq -r '(.seven_day?.utilization? // 0) | floor')
    EX_LIMIT=$(echo "$OAUTH_JSON" | jq -r '(.extra_usage?.monthly_limit? // 0)')
    EX_PCT=$(echo "$OAUTH_JSON" | jq -r '(.extra_usage?.utilization? // 0) | floor')
    UPDATED_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "used=0 max=0 pct=$SD_PCT period=7d updated=$UPDATED_ISO source=oauth" > "$OUT_FILE"
    COLOR_FH=$(bar_color "$FH_PCT")
    COLOR_SD=$(bar_color "$SD_PCT")
    BAR_FH=$(bar "$FH_PCT" 100 10 "$COLOR_FH")
    BAR_SD=$(bar "$SD_PCT" 100 "$BAR_WIDTH" "$COLOR_SD")
    LINE="  ${B}Claude OAuth${R}  5h: ${BAR_FH} ${B}${FH_PCT}%${R}  7d: ${BAR_SD} ${B}${SD_PCT}%${R}"
    [[ "${EX_LIMIT:-0}" != "0" ]] && LINE="${LINE}  ex: ${B}${EX_PCT}%${R}"
    echo -e "$LINE" >> "$OUT_FILE"
    exit 0
  fi
fi

# --- Fonte 1: Cursor /usage — não implementado ---
# (legado — requer CURSOR_API_KEY de conta Enterprise)
echo "Cursor API: não implementado — use claude-oauth-usage.sh" >&2

# --- Fonte 2: Anthropic Admin — não implementado ---
# (legado — requer ANTHROPIC_ADMIN_KEY)
write_fallback "not_implemented" "API usage: OAuth indisponível — configure ~/.claude/.credentials.json"
