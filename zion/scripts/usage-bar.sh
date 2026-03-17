#!/usr/bin/env bash
# usage-bar.sh — Gera barra de uso para bootstrap/status (duas fontes possíveis).
# 1) Cursor /usage (Current, Resets): CURSOR_API_KEY → POST api.cursor.com/teams/spend (Enterprise).
# 2) Anthropic (tokens 30d): ANTHROPIC_ADMIN_KEY → scripts/api-usage.sh (usage_report/messages).
# Escreve em .ephemeral/usage-bar.txt (linha 1 machine-readable, linha 2 humana).
# Uso: source ou bash; export WS=/workspace.
set -euo pipefail

WS="${WS:-/workspace}"
OUT_FILE="${OUT_FILE:-$WS/.ephemeral/usage-bar.txt}"
PERIOD="${USAGE_BAR_PERIOD:-30d}"
QUOTA_TOKENS="${USAGE_QUOTA_TOKENS:-275000000}"
BAR_WIDTH=22

mkdir -p "$(dirname "$OUT_FILE")"

R='\033[0m' B='\033[1m' DIM='\033[2m'
GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m' CYAN='\033[36m'
[[ ! -t 1 ]] && R="" B="" DIM="" GREEN="" YELLOW="" RED="" CYAN=""

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

# --- Fonte 1: Cursor /usage (Current + Resets) — mesmo conceito do painel /usage do Cursor ---
if [[ -n "${CURSOR_API_KEY:-}" ]] && command -v curl &>/dev/null && command -v jq &>/dev/null; then
  CURSOR_JSON=$(curl -sS -X POST "https://api.cursor.com/teams/spend" \
    -u "${CURSOR_API_KEY}:" \
    -H "Content-Type: application/json" \
    -d '{"page":1,"pageSize":100}' 2>/dev/null) || true
  if [[ -n "$CURSOR_JSON" ]] && echo "$CURSOR_JSON" | jq -e '.teamMemberSpend != null' &>/dev/null; then
    # subscriptionCycleStart = início do ciclo atual (epoch ms). "Resets" = próximo ciclo ≈ +1 mês
    CYCLE_START_MS=$(echo "$CURSOR_JSON" | jq -r '.subscriptionCycleStart // 0')
    SPEND_CENTS=$(echo "$CURSOR_JSON" | jq -r '[.teamMemberSpend[]? | (.spendCents // 0)] | add // 0')
    REQS=$(echo "$CURSOR_JSON" | jq -r '[.teamMemberSpend[]? | (.fastPremiumRequests // 0)] | add // 0')
    SPEND_DOLLARS=$(awk "BEGIN { printf \"%.2f\", $SPEND_CENTS/100 }" 2>/dev/null || echo "0")
    RESETS_DATE=""
    if [[ -n "$CYCLE_START_MS" && "$CYCLE_START_MS" != "0" && "$CYCLE_START_MS" != "null" ]]; then
      NEXT_SEC=$(( CYCLE_START_MS / 1000 + 31 * 24 * 3600 ))
      RESETS_DATE=$(date -d "@${NEXT_SEC}" +%d/%m 2>/dev/null || date -r "${NEXT_SEC}" +%d/%m 2>/dev/null || echo "?")
    fi
    UPDATED_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "source=cursor used_cents=$SPEND_CENTS used_reqs=$REQS cycle_start_ms=$CYCLE_START_MS updated=$UPDATED_ISO" > "$OUT_FILE"
    LINE1="  ${B}Cursor /usage:${R}  Current \$${SPEND_DOLLARS}  ${REQS} req"
    [[ -n "$RESETS_DATE" ]] && LINE1="${LINE1}  ${DIM}Resets ${RESETS_DATE}${R}"
    echo -e "$LINE1" >> "$OUT_FILE"
    exit 0
  fi
fi

# --- Fonte 2: Anthropic (tokens no período) — api-usage.sh ---
API_SCRIPT="$WS/scripts/api-usage.sh"
if [[ ! -f "$API_SCRIPT" ]]; then
  write_fallback "no_api_script" "API usage: script not found"
  exit 0
fi
if [[ -z "${ANTHROPIC_ADMIN_KEY:-}" ]]; then
  write_fallback "no_admin_key" "API usage: set ANTHROPIC_ADMIN_KEY (Anthropic) ou CURSOR_API_KEY (Cursor team)"
  exit 0
fi

JSON=$(bash "$API_SCRIPT" --json "$PERIOD" 2>/dev/null) || true
if [[ -z "$JSON" ]]; then
  write_fallback "fetch_failed" "API usage: fetch failed"
  exit 0
fi

USED=0
if command -v jq &>/dev/null; then
  USED=$(echo "$JSON" | jq -r '
    [.usage.data[]? | ((.input_tokens // 0) + (.output_tokens // 0))] | add // 0
  ' 2>/dev/null || echo 0)
fi

MAX="$QUOTA_TOKENS"
[[ "$MAX" -eq 0 ]] && MAX="$USED"
[[ "$MAX" -eq 0 ]] && MAX=1
PCT=$(( USED * 100 / MAX ))
[[ "$PCT" -gt 100 ]] && PCT=100

COLOR=$(bar_color "$PCT")
BAR_STR=$(bar "$USED" "$MAX" "$BAR_WIDTH" "$COLOR")
UPDATED_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "used=$USED max=$MAX pct=$PCT period=$PERIOD updated=$UPDATED_ISO" > "$OUT_FILE"
# Estilo tela de créditos: label + barra + "X% usado"
echo -e "  ${B}Uso API (${PERIOD})${R}" >> "$OUT_FILE"
echo -e "  ${BAR_STR}  ${B}${PCT}% usado${R}" >> "$OUT_FILE"
