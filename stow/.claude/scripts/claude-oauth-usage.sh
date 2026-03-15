#!/usr/bin/env bash
# claude-oauth-usage.sh — Uso do plano Claude via OAuth token
# Endpoint: api.anthropic.com/api/oauth/usage
# Token lido de: ~/.claude/.credentials.json (gerado pelo Claude Code CLI)
# Cache: ~/.cache/claude-usage.json (TTL 5min, evita rate limit)
#
# Uso:
#   claude-oauth-usage.sh              → JSON bruto (dados crus)
#   claude-oauth-usage.sh --waybar     → JSON para módulo custom/ waybar (return-type: json)
#   claude-oauth-usage.sh --statusline → uma linha para statusbar: 5h:9% 7d:96% ex:100%
#   claude-oauth-usage.sh --refresh    → força novo fetch (ignora cache)

set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CREDS_FILE="${CLAUDE_DIR}/.credentials.json"
CACHE_FILE="${XDG_CACHE_HOME:-${HOME}/.cache}/claude-usage.json"
CACHE_TTL=300  # segundos (5min)
FALLBACK="󱙺 --"

# --- deps ---
command -v jq   &>/dev/null || { echo "$FALLBACK"; exit 0; }
command -v curl &>/dev/null || { echo "$FALLBACK"; exit 0; }

# --- token ---
[[ -f "$CREDS_FILE" ]] || { echo "$FALLBACK"; exit 0; }
TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
[[ -n "$TOKEN" ]] || { echo "$FALLBACK"; exit 0; }

# --- cache ---
_cache_valid() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local age=$(( $(date +%s) - $(date -r "$CACHE_FILE" +%s 2>/dev/null || echo 0) ))
  [[ $age -lt $CACHE_TTL ]]
}

_fetch() {
  local json
  json=$(curl -sS --max-time 10 \
    'https://api.anthropic.com/api/oauth/usage' \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'anthropic-beta: oauth-2025-04-20' \
    -H 'anthropic-version: 2023-06-01' \
    -H 'Accept: application/json' 2>/dev/null) || return 1
  # validar: precisa ter five_hour
  echo "$json" | jq -e '.five_hour' &>/dev/null || return 1
  mkdir -p "$(dirname "$CACHE_FILE")"
  echo "$json" > "$CACHE_FILE"
  echo "$json"
}

_load() {
  if [[ "${1:-}" == "--refresh" ]] || ! _cache_valid; then
    _fetch || { [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE" || { echo "$FALLBACK"; exit 0; }; }
  else
    cat "$CACHE_FILE"
  fi
}

JSON=$(_load "${1:-}")

# --- saída padrão: JSON bruto ---
if [[ -z "${1:-}" || "${1:-}" == "--refresh" ]]; then
  echo "$JSON" | jq .
  exit 0
fi

# --- extrair ---
fh_pct=$(echo "$JSON"   | jq -r '.five_hour.utilization         // 0 | floor')
fh_reset=$(echo "$JSON" | jq -r '.five_hour.resets_at           // ""')
sd_pct=$(echo "$JSON"   | jq -r '.seven_day.utilization         // 0 | floor')
sd_reset=$(echo "$JSON" | jq -r '.seven_day.resets_at           // ""')
sn_pct=$(echo "$JSON"   | jq -r '.seven_day_sonnet.utilization  // "—"')
op_pct=$(echo "$JSON"   | jq -r '.seven_day_opus.utilization    // "—"')
ex_pct=$(echo "$JSON"   | jq -r '.extra_usage.utilization       // 0 | floor')
ex_used=$(echo "$JSON"  | jq -r '.extra_usage.used_credits      // 0 | floor')
ex_limit=$(echo "$JSON" | jq -r '.extra_usage.monthly_limit     // 0')

# formatar reset: "2026-03-17T19:00:00+00:00" → "17/03 19:00"
fmt_reset() {
  local ts="${1:-}"; [[ -z "$ts" ]] && echo "?" && return
  local dp="${ts%%T*}" tp="${ts#*T}"
  tp="${tp%%+*}"; tp="${tp%%.*}"; tp="${tp%:*}"
  local md="${dp#*-}"; local m="${md%%-*}"; local d="${md##*-}"
  echo "${d}/${m} ${tp}"
}
fh_r=$(fmt_reset "$fh_reset")
sd_r=$(fmt_reset "$sd_reset")

# pior pct para css class
max_pct=$(echo "$JSON" | jq '[
  (.five_hour.utilization   // 0),
  (.seven_day.utilization   // 0),
  (.extra_usage.utilization // 0)
] | max | floor')

css_class=""
(( max_pct >= 100 )) && css_class="critical" || true
(( max_pct >= 80 && max_pct < 100 )) && css_class="warning" || true

# --- --waybar ---
if [[ "${1:-}" == "--waybar" ]]; then
  text="󱙺 ${fh_pct}% · ${sd_pct}%"
  tooltip="5h: ${fh_pct}% (reset ${fh_r})&#10;7d: ${sd_pct}% (reset ${sd_r})&#10;Sonnet 7d: ${sn_pct}%&#10;Extra: ${ex_used}/${ex_limit} (${ex_pct}%)"
  jq -n \
    --arg text    "$text" \
    --arg tooltip "$tooltip" \
    --arg class   "$css_class" \
    '{"text": $text, "tooltip": $tooltip, "class": $class}'
  exit 0
fi

# --- --statusline ---
if [[ "${1:-}" == "--statusline" ]]; then
  printf '󱙺 5h:%s%% 7d:%s%% ex:%s%%' "$fh_pct" "$sd_pct" "$ex_pct"
  exit 0
fi
