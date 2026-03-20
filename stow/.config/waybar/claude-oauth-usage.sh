#!/usr/bin/env bash
# claude-oauth-usage.sh — Uso do plano Claude (OAuth ou claude.ai)
# Preferência: API claude.ai (sessionKey + org) → senão api.anthropic.com/api/oauth/usage
# sessionKey: .credentials.json, ~/.claude/claude-ai-session ou ~/.claude/cookies.txt (Netscape; extensão "Get cookies.txt")
# org: CLAUDE_AI_ORG_ID, cookies.txt (lastActiveOrg) ou hardcoded. Cache: ~/.cache/claude-usage.json
#
# Modos:
#   (sem args)       → JSON bruto + popula cache
#   --waybar         → JSON para módulo waybar (return-type: json)
#   --statusline     → uma linha: 󱙺 5h:9% 7d:96% ex:100%
#   --refresh        → força novo fetch ignorando cache
#   --refresh --waybar → refresh + output waybar JSON (para on-click)
#
# Cópia em .config/waybar/ para o Waybar achar sem depender de ~/scripts

set -euo pipefail

# Waybar não herda PATH do usuário — garantir que jq/curl sejam encontrados
export PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

# Credenciais: Claude Code CLI pode usar ~/.claude ou ~/.local/share/claude-code
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CREDS_FILE="${CLAUDE_DIR}/.credentials.json"
[[ ! -f "$CREDS_FILE" ]] && [[ -f "${HOME}/.local/share/claude-code/.credentials.json" ]] && CREDS_FILE="${HOME}/.local/share/claude-code/.credentials.json"
CACHE_FILE="${XDG_CACHE_HOME:-${HOME}/.cache}/claude-usage.json"
CACHE_LAST="${XDG_CACHE_HOME:-${HOME}/.cache}/claude-usage-last.json"
CACHE_TTL=60
# Suporta múltiplos args: --refresh --waybar
MODE=""
FORCE_REFRESH=0
for _arg in "$@"; do
  case "$_arg" in
    --refresh) FORCE_REFRESH=1 ;;
    --waybar|--statusline) MODE="$_arg" ;;
    *) [[ -z "$MODE" ]] && MODE="$_arg" ;;
  esac
done

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

# Barra "NO CLAUDE" no estilo da barra vermelha (sem credencial válida)
_no_claude_bar() {
  local tooltip="${1:-sem credencial ativa}"
  local red="#e74c3c"
  local pad=' '  # hair space (igual às barras azuis)
  local text="<span background=\"${red}\" color=\"#111111\">${pad}󱙺 NO</span><span color=\"${red}\">▓▓▓▓</span>"
  if [[ -n "${JQ:-}" ]] && command -v "$JQ" &>/dev/null; then
    $JQ -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "critical" '{text: $text, tooltip: $tooltip, class: $class}'
  else
    printf '{"text":"%s","tooltip":"%s","class":"critical"}\n' "${text//\"/\\\"}" "${tooltip//\"/\\\"}"
  fi
}

if [[ -z "$JQ" || -z "$CURL" ]]; then
  [[ "$MODE" == "--waybar" ]] && _no_claude_bar "jq/curl não encontrado" || echo "󱙺 --"
  exit 0
fi

# --- credenciais: OAuth token e/ou session (claude.ai) + org ---
# sessionKey: env → .credentials.json → claude-ai-session → cookies.txt
# org: env CLAUDE_AI_ORG_ID → cookies.txt (lastActiveOrg) → hardcoded
TOKEN=""
SESSION_KEY="${CLAUDE_AI_SESSION_KEY:-}"
ORG_ID="${CLAUDE_AI_ORG_ID:-}"

if [[ -f "$CREDS_FILE" ]]; then
  [[ -z "$TOKEN" ]] && TOKEN=$($JQ -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE" 2>/dev/null)
  if [[ -z "$SESSION_KEY" ]]; then
    SESSION_KEY=$($JQ -r '.sessionKey // .session_key // .cookie_session // .session // empty' "$CREDS_FILE" 2>/dev/null)
    [[ -z "$SESSION_KEY" || "$SESSION_KEY" == "null" ]] && SESSION_KEY=""
  fi
fi
if [[ -z "$SESSION_KEY" ]] && [[ -f "${CLAUDE_DIR}/claude-ai-session" ]]; then
  SESSION_KEY=$(head -1 "${CLAUDE_DIR}/claude-ai-session" 2>/dev/null)
fi
# ~/.claude.json (Claude Code às vezes guarda session/cookie aqui)
if [[ -z "$SESSION_KEY" ]] && [[ -f "${HOME}/.claude.json" ]]; then
  SESSION_KEY=$($JQ -r '.sessionKey // .session // .cookie_session // .oauthAccount.sessionKey // empty' "${HOME}/.claude.json" 2>/dev/null) || true
  [[ -z "$SESSION_KEY" || "$SESSION_KEY" == "null" ]] && SESSION_KEY=""
fi
# cookies.txt: Netscape (extensão "Get cookies.txt"); extrai sessionKey e lastActiveOrg
if [[ -f "${CLAUDE_DIR}/cookies.txt" ]]; then
  if [[ -z "$SESSION_KEY" ]]; then
    SESSION_KEY=$(awk -F'\t' 'tolower($1) ~ /claude\.ai/ && $6 == "sessionKey" {print $7; exit}' "${CLAUDE_DIR}/cookies.txt" 2>/dev/null)
  fi
  if [[ -z "$ORG_ID" ]]; then
    _o=$(awk -F'\t' 'tolower($1) ~ /claude\.ai/ && $6 == "lastActiveOrg" {print $7; exit}' "${CLAUDE_DIR}/cookies.txt" 2>/dev/null)
    [[ -n "$_o" ]] && ORG_ID="$_o"
  fi
fi
[[ -z "$ORG_ID" ]] && ORG_ID="995ebddd-ab0c-4ef8-aaf1-ad1fee25f624"

if [[ -z "$TOKEN" ]] && [[ -z "$SESSION_KEY" ]]; then
  [[ "$MODE" == "--waybar" ]] && _no_claude_bar "token OAuth ok; para 1%%/14%%/42%% use sessionKey em .credentials.json, .claude.json, claude-ai-session ou cookies.txt" || echo "󱙺 --"
  exit 0
fi

# --- cache helpers ---
_cache_valid() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local mtime now
  mtime=$(date -r "$CACHE_FILE" +%s 2>/dev/null) || return 1
  now=$(date +%s)
  (( now - mtime < CACHE_TTL ))
}

# --- fetch helpers ---
_fetch_claude_ai() {
  [[ -n "$SESSION_KEY" && -n "$ORG_ID" ]] || return 1
  local raw
  raw=$($CURL -sS --max-time 10 \
    "https://claude.ai/api/organizations/${ORG_ID}/usage" \
    -H "Accept: application/json" \
    -H "anthropic-client-platform: web_claude_ai" \
    -H "Content-Type: application/json" \
    --cookie "sessionKey=${SESSION_KEY}" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" 2>/dev/null) || return 1
  [[ -n "$(echo "$raw" | $JQ -r '.five_hour.utilization // empty' 2>/dev/null)" ]] || return 1
  mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null
  echo "$raw" > "$CACHE_FILE" 2>/dev/null || true
  cp "$CACHE_FILE" "$CACHE_LAST" 2>/dev/null || true
  mkdir -p "$(dirname "$SHARED_FILE")" 2>/dev/null || true
  cp "$CACHE_FILE" "$SHARED_FILE" 2>/dev/null || true
  echo "$raw"
}

_fetch_fresh() {
  [[ -n "$TOKEN" ]] || return 1
  local raw
  raw=$($CURL -sS --max-time 10 \
    'https://api.anthropic.com/api/oauth/usage' \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'anthropic-beta: oauth-2025-04-20' \
    -H 'anthropic-version: 2023-06-01' \
    -H 'Accept: application/json' 2>/dev/null) || return 1
  [[ -n "$(echo "$raw" | $JQ -r '.five_hour.utilization // empty' 2>/dev/null)" ]] || return 1
  mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null
  echo "$raw" > "$CACHE_FILE" 2>/dev/null || true
  cp "$CACHE_FILE" "$CACHE_LAST" 2>/dev/null || true
  mkdir -p "$(dirname "$SHARED_FILE")" 2>/dev/null || true
  cp "$CACHE_FILE" "$SHARED_FILE" 2>/dev/null || true
  echo "$raw"
}

# --- obter JSON: shared (container) → cache → fetch API → shared expirado → last ---
# Prioridade: shared file recente → cache local → fetch API → shared expirado (stale) → last known
# Nunca mostra NO enquanto houver qualquer dado salvo, independente da idade.
SHARED_FILE="${XDG_DATA_HOME:-${HOME}/.local/share}/zion/claude-usage.json"
USED_SOURCE=""
JSON=""

# checagem sem dependencia de jq/jaq: JSON valido tem "five_hour" no texto
_has_five_hour() { [[ "$1" == *'"five_hour"'* ]]; }

# 1. shared file do container — TTL 8h (container atualiza a cada sessao)
if [[ -f "$SHARED_FILE" ]] && [[ "$FORCE_REFRESH" != "1" ]]; then
  _shmtime=$(date -r "$SHARED_FILE" +%s 2>/dev/null) || _shmtime=0
  if (( $(date +%s) - _shmtime < 28800 )); then
    _tmp=$(cat "$SHARED_FILE" 2>/dev/null) && _has_five_hour "$_tmp" && JSON="$_tmp" && USED_SOURCE="container" || true
  fi
fi

# 2. cache local (60s TTL)
if [[ -z "$JSON" ]] && _cache_valid; then
  _tmp=$(cat "$CACHE_FILE" 2>/dev/null) && _has_five_hour "$_tmp" && JSON="$_tmp" && USED_SOURCE="cache" || true
fi

# 3. fetch da API (funciona se host tem acesso direto; no container sempre funciona)
if [[ -z "$JSON" ]] || [[ "$FORCE_REFRESH" == "1" ]]; then
  _fetched=$(_fetch_claude_ai 2>/dev/null) || true
  if [[ -n "$_fetched" ]] && _has_five_hour "$_fetched"; then
    JSON="$_fetched"; USED_SOURCE="claude.ai"
  else
    _fetched=$(_fetch_fresh 2>/dev/null) || true
    [[ -n "$_fetched" ]] && _has_five_hour "$_fetched" && JSON="$_fetched" && USED_SOURCE="OAuth" || true
  fi
fi

# 4. shared file expirado (stale) — melhor que NO
if [[ -z "$JSON" ]] && [[ -f "$SHARED_FILE" ]]; then
  _tmp=$(cat "$SHARED_FILE" 2>/dev/null) && _has_five_hour "$_tmp" && JSON="$_tmp" && USED_SOURCE="container(stale)" || true
fi

# 5. ultimo valor bom conhecido
if [[ -z "$JSON" ]] && [[ -f "$CACHE_LAST" ]]; then
  _tmp=$(cat "$CACHE_LAST" 2>/dev/null) && _has_five_hour "$_tmp" && JSON="$_tmp" && USED_SOURCE="last" || true
fi

if [[ -z "$JSON" ]]; then
  [[ "$MODE" == "--waybar" ]] && _no_claude_bar "sem dados — rode: zion claude usage --refresh" || echo "󱙺 --"
  exit 0
fi

# --- freshness: data do cache + cor do indicador ---
_file_age_label() {
  local f="${1:-}"; [[ -f "$f" ]] || { echo "[? old] ?"; return; }
  local mtime now mins
  mtime=$(date -r "$f" +%s 2>/dev/null) || { echo "[? old] ?"; return; }
  now=$(date +%s)
  mins=$(( (now - mtime) / 60 ))
  printf '[%dmin old] %s' "$mins" "$(date -r "$f" '+%d/%m %H:%M' 2>/dev/null || echo '?')"
}

DATA_DATE=""
FRESHNESS_COLOR=""
case "${USED_SOURCE:-}" in
  claude.ai|OAuth)
    DATA_DATE="[0min old] agora"
    FRESHNESS_COLOR="#2ecc71"
    FRESHNESS_LABEL="fresh"
    ;;
  cache)
    DATA_DATE=$(_file_age_label "$CACHE_FILE")
    FRESHNESS_COLOR="#2ecc71"
    FRESHNESS_LABEL="fresh"
    ;;
  container)
    DATA_DATE=$(_file_age_label "$SHARED_FILE")
    FRESHNESS_COLOR="#f39c12"
    FRESHNESS_LABEL="okayish"
    ;;
  "container(stale)"|last)
    _stale_file="$([[ "$USED_SOURCE" == "last" ]] && echo "$CACHE_LAST" || echo "$SHARED_FILE")"
    DATA_DATE=$(_file_age_label "$_stale_file")
    FRESHNESS_COLOR="#e74c3c"
    FRESHNESS_LABEL="ohno"
    ;;
  *)
    DATA_DATE="[? old] ?"
    FRESHNESS_COLOR="#e74c3c"
    FRESHNESS_LABEL="ohno"
    ;;
esac

# --- modo: JSON bruto ---
if [[ -z "$MODE" ]]; then
  echo "$JSON" | $JQ . 2>/dev/null || echo "$JSON"
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

# cor pango por percentual: cinza → verde → amarelo → vermelho
_color() {
  local pct="${1:-0}"
  (( pct >= 80 )) && echo "#e74c3c" && return
  (( pct >= 50 )) && echo "#f39c12" && return
  (( pct >= 10 )) && echo "#2ecc71" && return
  echo "#7f8c8d"
}

# Padding à esquerda do ícone (igual às barras azuis — hair space U+200A)
PAD_LEFT=' '

# gauge: ícone (opcional) + número dentro da caixa colorida, depois blocos
# Em 100%: só ícone + número, sem barra — exceto se $5=1 (tooltip: barra sempre desenhada).
# layout: [ icon DD]▓▓▓▓░░  ($1=icon, $2=pct, $3=w, $4=digits, $5=full_bar_no_hide)
_gauge() {
  local icon="${1:-}" pct="${2:-0}" w="${3:-4}" digits="${4:-2}" full_bar="${5:-}" color num filled seg i
  (( pct > 100 )) && pct=100
  if (( pct >= 100 )) && [[ "$full_bar" != "1" ]]; then
    color="#e74c3c"
    if [[ "$digits" == "3" ]]; then num="100"; else num="100"; fi
    printf '<span background="%s" color="#111111">%s%s%s</span>' \
      "$color" "$PAD_LEFT" "${icon:+$icon }" "$num"
    return
  fi
  if (( pct >= 100 )); then
    color="#e74c3c"
    filled=$w
    num="100"
  else
    color=$(_color "$pct")
    filled=$(( pct * w / 100 ))
    if [[ "$digits" == "3" ]]; then
      num=$(printf '%03d' "$pct")
    else
      num=$(printf '%02d' "$pct")
    fi
  fi
  seg=""
  for (( i=0; i<w; i++ )); do (( i < filled )) && seg+="▓" || seg+="░"; done
  printf '<span background="%s" color="#111111">%s%s%s</span><span color="%s">%s</span>' \
    "$color" "$PAD_LEFT" "${icon:+$icon }" "$num" "$color" "$seg"
}

# gauge dourado: créditos extras. Em 100%: só ícone + número, sem barra — exceto se $5=1 (tooltip).
_gauge_gold() {
  local icon="${1:-}" pct="${2:-0}" w="${3:-4}" digits="${4:-2}" full_bar="${5:-}" gold="#d4af37" num filled seg i
  (( pct > 100 )) && pct=100
  if (( pct >= 100 )) && [[ "$full_bar" != "1" ]]; then
    num="100"
    printf '<span background="%s" color="#1a1a0a">%s%s%s</span>' \
      "$gold" "$PAD_LEFT" "${icon:+$icon }" "$num"
    return
  fi
  if (( pct >= 100 )); then
    filled=$w
    num="100"
  else
    filled=$(( pct * w / 100 ))
    if [[ "$digits" == "3" ]]; then
      num=$(printf '%03d' "$pct")
    else
      num=$(printf '%02d' "$pct")
    fi
  fi
  seg=""
  for (( i=0; i<w; i++ )); do (( i < filled )) && seg+="▓" || seg+="░"; done
  printf '<span background="%s" color="#1a1a0a">%s%s%s</span><span color="%s">%s</span>' \
    "$gold" "$PAD_LEFT" "${icon:+$icon }" "$num" "$gold" "$seg"
}

sn_num=$(echo "$JSON" | $JQ -r '(.seven_day_sonnet?.utilization? // 0) | floor')

# Ícones por barra (Nerd Font): Sonnet, 5h, 7d, Opus, Extra
ICON_SONNET='󱙺'   # star-shooting (AI/Sonnet — limite semanal Sonnet)
ICON_5H='󱦟'       # timer-sand-empty (sessão ~5h — ampulheta vazia)
ICON_7D='󰸗'       # calendar-week (limite semanal — todos os modelos)
ICON_OPUS='󰐂'     # opus/premium (só no tooltip)

# --- modo: --waybar ---
if [[ "$MODE" == "--waybar" ]]; then
  text="$(_gauge "$ICON_5H" "$fh_pct") $(_gauge "$ICON_SONNET" "$sn_num") $(_gauge "$ICON_7D" "$sd_pct")"
  tw=12
  wprefix=12
  p_5h=$(printf "%-${wprefix}s" "${ICON_5H} 5h");   line_5h="${p_5h}$(_gauge "" "$fh_pct" "$tw" 3 1)   reset em $fh_r"
  p_7d=$(printf "%-${wprefix}s" "${ICON_7D} 7d");   line_7d="${p_7d}$(_gauge "" "$sd_pct" "$tw" 3 1)   reset em $sd_r"
  p_sn=$(printf "%-${wprefix}s" "${ICON_SONNET} Sonnet"); line_sn="${p_sn}$(_gauge "" "$sn_pct" "$tw" 3 1)"
  p_op=$(printf "%-${wprefix}s" "${ICON_OPUS} Opus");   line_op="${p_op}$(_gauge "" "$op_pct" "$tw" 3 1)"
  # Primeira linha do tooltip: sessionKey e org + fonte dos dados + indicador de frescor
  sk_status="sessionKey: $([[ -n "$SESSION_KEY" ]] && echo "sim" || echo "não")"
  org_status="org: $([[ -n "$ORG_ID" ]] && echo "${ORG_ID:0:8}…" || echo "não")"
  freshness_dot="<span color='${FRESHNESS_COLOR}'>●</span>"
  source_line="${freshness_dot} ${FRESHNESS_LABEL}  ${DATA_DATE}"
  tooltip="<span font_family='monospace' size='12000'>${source_line}"$'\n'"$(printf '%s\n%s\n%s\n%s' "$line_5h" "$line_7d" "$line_sn" "$line_op")</span>"
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
