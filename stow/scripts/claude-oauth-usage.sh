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

# --- deps: suporta jq/jaq e curl/xh/wget ---
JQ=""
for _b in jq jaq; do
  if command -v "$_b" &>/dev/null; then JQ="$_b"; break; fi
done
# fallback: caminhos absolutos NixOS
if [[ -z "$JQ" ]]; then
  for _p in /run/current-system/sw/bin/jq /run/current-system/sw/bin/jaq \
            "$HOME/.nix-profile/bin/jq" "$HOME/.nix-profile/bin/jaq" \
            /nix/var/nix/profiles/default/bin/jq; do
    [[ -x "$_p" ]] && JQ="$_p" && break
  done
fi

CURL=""
for _b in curl xh wget; do
  if command -v "$_b" &>/dev/null; then CURL="$_b"; break; fi
done
if [[ -z "$CURL" ]]; then
  for _p in /run/current-system/sw/bin/curl /run/current-system/sw/bin/xh \
            "$HOME/.nix-profile/bin/curl" "$HOME/.nix-profile/bin/xh"; do
    [[ -x "$_p" ]] && CURL="$_p" && break
  done
fi

if [[ -z "$JQ" || -z "$CURL" ]]; then
  [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 --","tooltip":"jq/curl não encontrado","class":""}' || echo "󱙺 --"
  exit 0
fi

# --- token ---
if [[ ! -f "$CREDS_FILE" ]]; then
  [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 --","tooltip":"credentials não encontrado","class":""}' || echo "󱙺 --"
  exit 0
fi
TOKEN=$($JQ -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
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
  raw=$($CURL -sS --max-time 10 \
    'https://api.anthropic.com/api/oauth/usage' \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'anthropic-beta: oauth-2025-04-20' \
    -H 'anthropic-version: 2023-06-01' \
    -H 'Accept: application/json' 2>/dev/null) || return 1
  # só salva se tiver five_hour (resposta válida)
  echo "$raw" | $JQ -e '.five_hour' &>/dev/null || return 1
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
if [[ -z "$JSON" ]] || ! echo "$JSON" | $JQ -e '.five_hour' &>/dev/null; then
  # se tem cache antigo, usa mesmo expirado
  if [[ -f "$CACHE_FILE" ]] && $JQ -e '.five_hour' "$CACHE_FILE" &>/dev/null; then
    JSON=$(cat "$CACHE_FILE")
  else
    [[ "$MODE" == "--waybar" ]] && echo '{"text":"󱙺 rate limit","tooltip":"API limitada. Aguarde.","class":"warning"}' || echo "󱙺 rate limit"
    exit 0
  fi
fi

# --- modo: JSON bruto ---
if [[ -z "$MODE" || "$MODE" == "--refresh" ]]; then
  echo "$JSON" | $JQ .
  exit 0
fi

# --- extrair campos (jaq-safe: usar ? em objetos que podem ser null) ---
fh_pct=$(echo "$JSON"   | $JQ -r '(.five_hour?.utilization?         // 0) | floor')
fh_reset=$(echo "$JSON" | $JQ -r '(.five_hour?.resets_at?           // "")')
sd_pct=$(echo "$JSON"   | $JQ -r '(.seven_day?.utilization?         // 0) | floor')
sd_reset=$(echo "$JSON" | $JQ -r '(.seven_day?.resets_at?           // "")')
sn_pct=$(echo "$JSON"   | $JQ -r '(.seven_day_sonnet?.utilization?  // 0) | floor')
op_pct=$(echo "$JSON"   | $JQ -r '(.seven_day_opus?.utilization?    // 0) | floor')
ex_pct=$(echo "$JSON"   | $JQ -r '(.extra_usage?.utilization?       // 0) | floor')
ex_used=$(echo "$JSON"  | $JQ -r '(.extra_usage?.used_credits?      // 0) | floor')
ex_limit=$(echo "$JSON" | $JQ -r '(.extra_usage?.monthly_limit?     // 0)')

# tempo restante até reset (ex: "1h30m", "45m", "já resetou")
_time_until() {
  local ts="${1:-}"; [[ -z "$ts" ]] && echo "?" && return
  local now reset_epoch diff h m
  now=$(date +%s)
  reset_epoch=$(date -d "$ts" +%s 2>/dev/null) || { echo "?"; return; }
  diff=$(( reset_epoch - now ))
  (( diff <= 0 )) && echo "já resetou" && return
  h=$(( diff / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  (( h > 0 )) && printf '%dh%02dm' "$h" "$m" || printf '%dm' "$m"
}
fh_r=$(  _time_until "$fh_reset")
sd_r=$(  _time_until "$sd_reset")

# cor pango por percentual: branco → verde → amarelo → vermelho
_color() {
  local pct="${1:-0}"
  (( pct >= 80 )) && echo "#e74c3c" && return
  (( pct >= 50 )) && echo "#f39c12" && return
  (( pct >= 10 )) && echo "#2ecc71" && return
  echo "#ffffff"
}

# gauge: número no início, blocos depois, sem label
# layout: [DD]▓▓▓▓░░  (w=4 na barra; w maior no tooltip)
# uso: _gauge pct [w]; _gauge_gold pct [w]
_gauge() {
  local pct="${1:-0}" w="${2:-4}" color num filled seg i
  if (( pct >= 100 )); then
    color="#e74c3c"
    num="100"
    filled=$w
  else
    color=$(_color "$pct")
    num=$(printf '%02d' "$pct")
    filled=$(( pct * w / 100 ))
  fi
  seg=""
  for (( i=0; i<w; i++ )); do (( i < filled )) && seg+="▓" || seg+="░"; done
  printf '<span background="%s" color="#111111">%s</span><span color="%s">%s</span>' \
    "$color" "$num" "$color" "$seg"
}

# gauge dourado: créditos extras (mesmo layout, cor fixa gold)
_gauge_gold() {
  local pct="${1:-0}" w="${2:-4}" gold="#d4af37" num filled seg i
  if (( pct >= 100 )); then
    num="100"
    filled=$w
  else
    num=$(printf '%02d' "$pct")
    filled=$(( pct * w / 100 ))
  fi
  seg=""
  for (( i=0; i<w; i++ )); do (( i < filled )) && seg+="▓" || seg+="░"; done
  printf '<span background="%s" color="#1a1a0a">%s</span><span color="%s">%s</span>' \
    "$gold" "$num" "$gold" "$seg"
}

sn_num=$(echo "$JSON" | $JQ -r '(.seven_day_sonnet?.utilization? // 0) | floor')

# --- modo: --waybar ---
if [[ "$MODE" == "--waybar" ]]; then
  text="$(_gauge "$sn_num") $(_gauge "$fh_pct") $(_gauge "$sd_pct") $(_gauge_gold "$ex_pct")"
  # tooltip: tabela monospace, barrinhas maiores (w=12)
  local tw=12
  local pad
  pad=$(printf '%-10s' "5h");       line_5h="${pad}$(_gauge "$fh_pct" "$tw")   reset em $fh_r"
  pad=$(printf '%-10s' "7d");       line_7d="${pad}$(_gauge "$sd_pct" "$tw")   reset em $sd_r"
  pad=$(printf '%-10s' "Sonnet 7d"); line_sn="${pad}$(_gauge "$sn_pct" "$tw")"
  pad=$(printf '%-10s' "Opus 7d");  line_op="${pad}$(_gauge "$op_pct" "$tw")"
  pad=$(printf '%-10s' "Extra");    line_ex="${pad}$(_gauge_gold "$ex_pct" "$tw")   ${ex_used}/${ex_limit}"
  tooltip="<span font_family='monospace' size='12000'>$(printf '%s\n%s\n%s\n%s\n%s' "$line_5h" "$line_7d" "$line_sn" "$line_op" "$line_ex")</span>"
  $JQ -cn \
    --arg text    "$text" \
    --arg tooltip "$tooltip" \
    --arg class   "" \
    '{"text": $text, "tooltip": $tooltip, "class": $class}'
  exit 0
fi

# --- modo: --statusline ---
if [[ "$MODE" == "--statusline" ]]; then
  printf '󱙺 5h:%s%% 7d:%s%% ex:%s%%' "$fh_pct" "$sd_pct" "$ex_pct"
  exit 0
fi
