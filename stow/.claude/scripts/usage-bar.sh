#!/usr/bin/env bash
# usage-bar.sh — Gera barra compacta de uso API Anthropic (mesma fonte que api-usage.sh)
# Escreve em .ephemeral/usage-bar.txt para leitura por user e agente (decisão por cota).
# Uso: source ou bash; export WS=/workspace. Atualiza o arquivo no lugar.
set -euo pipefail

WS="${WS:-/workspace}"
OUT_FILE="${OUT_FILE:-$WS/.ephemeral/usage-bar.txt}"
PERIOD="${USAGE_BAR_PERIOD:-30d}"
# Cota mensal em tokens (input+output). 0 = só exibir usado, sem barra de %
QUOTA_TOKENS="${USAGE_QUOTA_TOKENS:-275000000}"
BAR_WIDTH=22

mkdir -p "$(dirname "$OUT_FILE")"

# Cores (strip se não for TTY)
R='\033[0m' B='\033[1m' DIM='\033[2m'
GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m' CYAN='\033[36m'
[[ ! -t 1 ]] && R="" B="" DIM="" GREEN="" YELLOW="" RED="" CYAN=""

# Barra horizontal (value, max, width, color_hex) — mesmo estilo do dashboard
bar() {
  local value="$1" max="$2" width="${3:-20}" color="$4"
  local fill=0
  if [[ "${max:-0}" -gt 0 ]]; then
    fill=$(( value * width / max ))
  fi
  [[ $fill -gt $width ]] && fill=$width
  local empty=$(( width - fill ))
  printf '%b' "$color"
  printf '%*s' "$fill" '' | tr ' ' '━'
  printf '%b' "$DIM"
  printf '%*s' "$empty" '' | tr ' ' '─'
  printf '%b' "$R"
}

# Cor por faixa de uso (0–100%)
bar_color() {
  local pct="$1"
  if [[ "$pct" -lt 60 ]]; then
    echo -ne "$GREEN"
  elif [[ "$pct" -lt 85 ]]; then
    echo -ne "$YELLOW"
  else
    echo -ne "$RED"
  fi
}

API_SCRIPT="$WS/scripts/api-usage.sh"
if [[ ! -f "$API_SCRIPT" ]]; then
  echo "used=0 max=0 pct=0 period=$PERIOD updated=$(date -u +%Y-%m-%dT%H:%M:%SZ) error=no_api_script" > "$OUT_FILE"
  echo -e "${DIM}API usage: script not found${R}" >> "$OUT_FILE"
  exit 0
fi

# Requer ANTHROPIC_ADMIN_KEY
if [[ -z "${ANTHROPIC_ADMIN_KEY:-}" ]]; then
  echo "used=0 max=0 pct=0 period=$PERIOD updated=$(date -u +%Y-%m-%dT%H:%M:%SZ) error=no_admin_key" > "$OUT_FILE"
  echo -e "${DIM}API usage: set ANTHROPIC_ADMIN_KEY${R}" >> "$OUT_FILE"
  exit 0
fi

JSON=""
JSON=$(bash "$API_SCRIPT" --json "$PERIOD" 2>/dev/null) || true

if [[ -z "$JSON" ]]; then
  echo "used=0 max=0 pct=0 period=$PERIOD updated=$(date -u +%Y-%m-%dT%H:%M:%SZ) error=fetch_failed" > "$OUT_FILE"
  echo -e "${DIM}API usage: fetch failed${R}" >> "$OUT_FILE"
  exit 0
fi

# Totais de tokens (input + output) do período
USED=0
if command -v jq &>/dev/null; then
  USED=$(echo "$JSON" | jq -r '
    [.usage.data[]? | ((.input_tokens // 0) + (.output_tokens // 0))] | add // 0
  ' 2>/dev/null || echo 0)
fi

# Se cota não definida ou 0, usar "used" como 100% para a barra (só informativo)
MAX="$QUOTA_TOKENS"
[[ "$MAX" -eq 0 ]] && MAX="$USED"
[[ "$MAX" -eq 0 ]] && MAX=1

PCT=$(( USED * 100 / MAX ))
[[ "$PCT" -gt 100 ]] && PCT=100

COLOR=$(bar_color "$PCT")
BAR_STR=$(bar "$USED" "$MAX" "$BAR_WIDTH" "$COLOR")

# Formato humano: [████░░] 42%  115M/275M (30d)  10:15
USED_M=$(( USED / 1000000 ))
MAX_M=$(( MAX / 1000000 ))
UPDATED=$(date +%H:%M)

LINE1="  ${B}API ${PERIOD}:${R} [${BAR_STR}] ${B}${PCT}%${R}  ${USED_M}M/${MAX_M}M tok  ${DIM}${UPDATED}${R}"

# Machine-readable (linha 2) — agente usa para decisão
UPDATED_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "used=$USED max=$MAX pct=$PCT period=$PERIOD updated=$UPDATED_ISO" > "$OUT_FILE"
echo -e "$LINE1" >> "$OUT_FILE"
