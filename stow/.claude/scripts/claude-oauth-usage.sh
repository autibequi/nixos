#!/usr/bin/env bash
# claude-oauth-usage.sh — Uso do plano Claude via OAuth token
# Endpoint: api.anthropic.com/api/oauth/usage
# Token: ~/.claude/.credentials.json (gerado pelo Claude Code CLI)
# Cache: ~/.cache/claude-usage.json (TTL 5min — evita rate limit)
#
# Modos:
#   (sem args)       → JSON bruto + popula cache
#   --waybar         → JSON para módulo waybar (return-type: json)
#   --statusline     → uma linha: 󱙺 5h:9% 7d:96% ex:100%
#   --refresh        → força novo fetch ignorando cache

set -euo pipefail

# Waybar não herda PATH do usuário — garantir que jq/curl sejam encontrados
export PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CREDS_FILE="${CLAUDE_DIR}/.credentials.json"
CACHE_FILE="${XDG_CACHE_HOME:-${HOME}/.cache}/claude-usage.json"
CACHE_TTL=300  # 5 minutos
MODE="${1:-}"

# --- deps ---
if ! command -v jq &>/dev/null || ! command -v curl &>/dev/null; then
  [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 --","tooltip":"jq/curl não encontrado","class":""}' || echo "󱙺 --"
  exit 0
fi

# --- token ---
if [[ ! -f "$CREDS_FILE" ]]; then
  [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 --","tooltip":"credentials não encontrado","class":""}' || echo "󱙺 --"
  exit 0
fi
TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
if [[ -z "$TOKEN" ]]; then
  [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 --","tooltip":"token não encontrado","class":""}' || echo "󱙺 --"
  exit 0
fi

# --- cache helpers ---
_cache_valid() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local mtime now age
  mtime=$(date -r "$CACHE_FILE" +%s 2>/dev/null) || return 1
  now=$(date +%s)
  age=$(( now - mtime ))
  (( age < CACHE_TTL ))
}

_fetch_fresh() {
  local raw
  raw=$(curl -sS --max-time 10 \
    'https://api.anthropic.com/api/oauth/usage' \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'anthropic-beta: oauth-2025-04-20' \
    -H 'anthropic-version: 2023-06-01' \
    -H 'Accept: application/json' 2>/dev/null) || return 1
  # só salva se tiver five_hour (resposta válida)
  echo "$raw" | jq -e '.five_hour' &>/dev/null || return 1
  mkdir -p "$(dirname "$CACHE_FILE")"
  echo "$raw" > "$CACHE_FILE"
  echo "$raw"
}

# --- obter JSON (cache ou fetch) ---
JSON=""
if [[ "$MODE" == "--refresh" ]]; then
  JSON=$(_fetch_fresh 2>/dev/null) || true
else
  if _cache_valid; then
    JSON=$(cat "$CACHE_FILE")
  else
    JSON=$(_fetch_fresh 2>/dev/null) || true
  fi
fi

# sem dados: fallback
if [[ -z "$JSON" ]] || ! echo "$JSON" | jq -e '.five_hour' &>/dev/null; then
  # se tem cache antigo, usa mesmo expirado
  if [[ -f "$CACHE_FILE" ]] && jq -e '.five_hour' "$CACHE_FILE" &>/dev/null; then
    JSON=$(cat "$CACHE_FILE")
  else
    [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 rate limit","tooltip":"API limitada. Aguarde.","class":"warning"}' || echo "󱙺 rate limit"
    exit 0
  fi
fi

# --- modo: JSON bruto ---
if [[ -z "$MODE" || "$MODE" == "--refresh" ]]; then
  echo "$JSON" | jq .
  exit 0
fi

# --- extrair campos ---
fh_pct=$(echo "$JSON"   | jq -r '.five_hour.utilization         // 0 | floor')
fh_reset=$(echo "$JSON" | jq -r '.five_hour.resets_at           // ""')
sd_pct=$(echo "$JSON"   | jq -r '.seven_day.utilization         // 0 | floor')
sd_reset=$(echo "$JSON" | jq -r '.seven_day.resets_at           // ""')
sn_pct=$(echo "$JSON"   | jq -r '.seven_day_sonnet.utilization  // "—"')
op_pct=$(echo "$JSON"   | jq -r '.seven_day_opus.utilization    // "—"')
ex_pct=$(echo "$JSON"   | jq -r '.extra_usage.utilization       // 0 | floor')
ex_used=$(echo "$JSON"  | jq -r '.extra_usage.used_credits      // 0 | floor')
ex_limit=$(echo "$JSON" | jq -r '.extra_usage.monthly_limit     // 0')

# formatar reset timestamp
fmt_reset() {
  local ts="${1:-}"; [[ -z "$ts" ]] && echo "?" && return
  local dp="${ts%%T*}" tp="${ts#*T}"
  tp="${tp%%+*}"; tp="${tp%%.*}"; tp="${tp%:*}"
  local md="${dp#*-}"; echo "${md##*-}/${md%%-*} ${tp}"
}
fh_r=$(fmt_reset "$fh_reset")
sd_r=$(fmt_reset "$sd_reset")

# pior pct → css class
max_pct=$(echo "$JSON" | jq '[(.five_hour.utilization // 0), (.seven_day.utilization // 0), (.extra_usage.utilization // 0)] | max | floor')
css_class=""
(( max_pct >= 100 )) && css_class="critical" || true
(( max_pct >= 80 && max_pct < 100 )) && css_class="warning" || true

# --- modo: --waybar ---
if [[ "$MODE" == "--waybar" ]]; then
  jq -n \
    --arg text    "󱙺 ${fh_pct}% · ${sd_pct}%" \
    --arg tooltip "5h: ${fh_pct}% (reset ${fh_r})&#10;7d: ${sd_pct}% (reset ${sd_r})&#10;Sonnet 7d: ${sn_pct}%&#10;Opus 7d: ${op_pct}%&#10;Extra: ${ex_used}/${ex_limit} (${ex_pct}%)" \
    --arg class   "$css_class" \
    '{"text": $text, "tooltip": $tooltip, "class": $class}'
  exit 0
fi

# --- modo: --statusline ---
if [[ "$MODE" == "--statusline" ]]; then
  printf '󱙺 5h:%s%% 7d:%s%% ex:%s%%' "$fh_pct" "$sd_pct" "$ex_pct"
  exit 0
fi
