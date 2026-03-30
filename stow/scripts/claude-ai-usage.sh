#!/usr/bin/env bash
# claude-ai-usage.sh — Uso via API web claude.ai (Settings > Uso).
# Modos: (vazio) linha texto | --waybar JSON | --statusline | --json | --debug
set -euo pipefail

export PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

JQ=""
for _b in jq jaq; do
  if command -v "$_b" &>/dev/null; then JQ="$_b"; break; fi
done
if [[ -z "$JQ" ]]; then
  for _p in /run/current-system/sw/bin/jq /run/current-system/sw/bin/jaq \
            "$HOME/.nix-profile/bin/jq" "$HOME/.nix-profile/bin/jaq"; do
    [[ -x "$_p" ]] && JQ="$_p" && break
  done
fi

CURL=""
for _b in curl xh wget; do
  if command -v "$_b" &>/dev/null; then CURL="$_b"; break; fi
done

MODE="${1:-}"
SESSION_KEY="${CLAUDE_AI_SESSION_KEY:-}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"

ORG_ID="${CLAUDE_AI_ORG_ID:-}"
if [[ -z "$ORG_ID" ]] && [[ -n "$JQ" ]]; then
  if [[ -f "${CLAUDE_DIR}/.credentials.json" ]]; then
    ORG_ID=$($JQ -r '.organizationUuid // .organization_id // .oauthAccount.organizationUuid // empty' "${CLAUDE_DIR}/.credentials.json" 2>/dev/null)
  fi
  if [[ -z "$ORG_ID" || "$ORG_ID" == "null" ]] && [[ -f "${HOME}/.claude.json" ]]; then
    ORG_ID=$($JQ -r '.oauthAccount.organizationUuid // empty' "${HOME}/.claude.json" 2>/dev/null)
  fi
fi
ORG_ID="${ORG_ID:-995ebddd-ab0c-4ef8-aaf1-ad1fee25f624}"

if [[ -z "$SESSION_KEY" && -f "${CLAUDE_DIR}/claude-ai-session" ]]; then
  SESSION_KEY=$(head -1 "${CLAUDE_DIR}/claude-ai-session")
fi
if [[ -z "$SESSION_KEY" && -f "${CLAUDE_DIR}/.credentials.json" ]] && [[ -n "$JQ" ]]; then
  SESSION_KEY=$($JQ -r '.sessionKey // .session_key // .cookie_session // .session // empty' "${CLAUDE_DIR}/.credentials.json" 2>/dev/null)
  if [[ -z "$SESSION_KEY" || "$SESSION_KEY" == "null" ]]; then
    ACCESS_TOKEN=$($JQ -r '.claudeAiOauth.accessToken // empty' "${CLAUDE_DIR}/.credentials.json" 2>/dev/null)
  fi
fi
if [[ -z "$SESSION_KEY" && -z "${ACCESS_TOKEN:-}" && -f "${CLAUDE_DIR}/credentials.json" ]] && [[ -n "$JQ" ]]; then
  SESSION_KEY=$($JQ -r '.sessionKey // .session_key // .cookie_session // .session // empty' "${CLAUDE_DIR}/credentials.json" 2>/dev/null)
  if [[ -z "$SESSION_KEY" || "$SESSION_KEY" == "null" ]]; then
    ACCESS_TOKEN=$($JQ -r '.claudeAiOauth.accessToken // empty' "${CLAUDE_DIR}/credentials.json" 2>/dev/null)
  fi
fi
if [[ -z "$SESSION_KEY" && -f "${HOME}/.config/claude-ai-session" ]]; then
  SESSION_KEY=$(head -1 "${HOME}/.config/claude-ai-session")
fi

_fail_out() {
  local tip="$1"
  if [[ "$MODE" == "--waybar" ]]; then
    $JQ -cn --arg t "$tip" '{text: "󱙺 --", tooltip: $t, class: "warning"}'
  else
    echo "󱙺 --"
    echo "$tip" >&2
  fi
}

[[ -z "$SESSION_KEY" && -z "${ACCESS_TOKEN:-}" ]] && {
  _fail_out "sem session — defina CLAUDE_AI_SESSION_KEY ou ${CLAUDE_DIR}/claude-ai-session"
  exit 0
}

[[ -z "$JQ" || -z "$CURL" ]] && {
  _fail_out "jq ou curl não encontrado"
  exit 0
}

AUTH_ARGS=()
if [[ -n "${ACCESS_TOKEN:-}" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer ${ACCESS_TOKEN}")
else
  AUTH_ARGS=(--cookie "sessionKey=${SESSION_KEY}")
fi

URL="https://claude.ai/api/organizations/${ORG_ID}/usage"
RESP=$($CURL -sS --max-time 15 "$URL" \
  -H "Accept: application/json" \
  -H "anthropic-client-platform: web_claude_ai" \
  -H "Content-Type: application/json" \
  "${AUTH_ARGS[@]}" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -w "\n%{http_code}" 2>/dev/null) || { _fail_out "curl falhou"; exit 0; }

HTTP_CODE=$(echo "$RESP" | tail -n1)
JSON=$(echo "$RESP" | sed '$d')

if [[ "$HTTP_CODE" != "200" ]]; then
  _fail_out "HTTP ${HTTP_CODE} — org UUID errada ou sessão expirada (não use lastOrg como texto; use oauthAccount.organizationUuid)"
  [[ "$MODE" != "--waybar" ]] && echo "body: ${JSON:0:300}" >&2
  exit 0
fi

if ! echo "$JSON" | $JQ -e . >/dev/null 2>&1; then
  _fail_out "resposta não é JSON (login/captcha?)"
  exit 0
fi

if [[ "$MODE" == "--json" ]]; then
  echo "$JSON"
  exit 0
fi

if [[ "$MODE" == "--debug" ]]; then
  echo "$JSON" | $JQ . 2>/dev/null || echo "$JSON"
  echo "--- http=$HTTP_CODE org=$ORG_ID ---" >&2
  exit 0
fi

# pct: 0–1 → %; 1–100 → já é %; nunca >100 na saída
norm_line() {
  echo "$JSON" | $JQ -r "$1" 2>/dev/null | head -1
}

# Só normaliza fração 0–1 → %; resto passa cru para o awk corrigir escala / limitar a 100
JQ_PCT='def pct_raw:
  if . == null or (type != "number") then 0
  elif . < 0 then 0
  elif . <= 1 then . * 100
  else .
  end;'

pick_first_nonzero() {
  local v
  for v in "$@"; do
    if [[ -n "$v" && "$v" != "null" && "$v" != "0" ]]; then
      echo "$v"
      return
    fi
  done
  echo "0"
}

# Duas fontes (seven_day vs weekly_limits no JSON web) podem divergir; o primeiro não-zero
# nem sempre é o do dashboard — usar o maior após pct_raw alinha melhor com Settings > Uso.
max_pct() {
  awk -v a="${1:-0}" -v b="${2:-0}" 'BEGIN { a+=0; b+=0; print (a >= b) ? a : b }'
}

# --- OAuth-shaped ---
fh=$(norm_line "${JQ_PCT} (.five_hour.utilization // .fiveHour.utilization // 0) | pct_raw")
sd=$(norm_line "${JQ_PCT} (.seven_day.utilization // .sevenDay.utilization // 0) | pct_raw")
sn_o=$(norm_line "${JQ_PCT} (.seven_day_sonnet.utilization // .sevenDaySonnet.utilization // 0) | pct_raw")

# --- Web-shaped ---
sess=$(norm_line "${JQ_PCT}
  ( (.usage // .data // {}) as \$u | \$u.current_session.percentage_used // \$u.currentSession.percentageUsed // \$u.session.percentage_used // empty )
  // .current_session.percentage_used // .currentSession.percentageUsed // .session.percentage_used // 0 | pct_raw")

week_all=$(norm_line "${JQ_PCT}
  def lim: . as \$r | (\$r.usage // \$r.data // {}) as \$u
    | [ (\$u.weekly_limits // [])[] , (\$u.weeklyLimits // [])[] , (\$r.weekly_limits // [])[] , (\$r.weeklyLimits // [])[] ]
    | map(select(type == \"object\"));
  lim
  | map(select(.name == \"all_models\" or .name == \"allModels\" or .identifier == \"all_models\" or .type == \"all\"))
  | first // {}
  | (.percentage_used // .percentageUsed // .utilization // 0) | pct_raw")

week_sn=$(norm_line "${JQ_PCT}
  def lim: . as \$r | (\$r.usage // \$r.data // {}) as \$u
    | [ (\$u.weekly_limits // [])[] , (\$u.weeklyLimits // [])[] , (\$r.weekly_limits // [])[] , (\$r.weeklyLimits // [])[] ]
    | map(select(type == \"object\"));
  lim
  | map(select(.name == \"sonnet\" or .identifier == \"sonnet\" or .type == \"sonnet\"))
  | first // {}
  | (.percentage_used // .percentageUsed // .utilization // 0) | pct_raw")

sess_pct=$(pick_first_nonzero "$sess" "$fh")
semana_pct=$(max_pct "$sd" "$week_all")
sonnet_pct=$(max_pct "$sn_o" "$week_sn")

round() {
  printf '%.0f' "${1:-0}" 2>/dev/null || echo 0
}

sess_pct=$(round "$sess_pct")
semana_pct=$(round "$semana_pct")
sonnet_pct=$(round "$sonnet_pct")

# API costuma mandar inteiros ×10 (320 → 32%) ou ×100 (3200 → 32%). Só escala se os três > 100.
awk_fix_scale() {
  awk -v s="$sess_pct" -v w="$semana_pct" -v n="$sonnet_pct" 'function ok(x) { return (x >= 0 && x <= 100) }
  function fix(v,    v10,v100) {
    if (v <= 100) return v
    v10 = v/10; v100 = v/100
    if (v >= 1000 && ok(v100)) return v100
    if (ok(v10)) return v10
    if (ok(v100)) return v100
    return 100
  }
  BEGIN {
    s+=0; w+=0; n+=0
    s = fix(s); w = fix(w); n = fix(n)
    if (s < 0) s = 0
    if (w < 0) w = 0
    if (n < 0) n = 0
    printf "%.0f %.0f %.0f", s, w, n
  }'
}
read -r sess_pct semana_pct sonnet_pct <<< "$(awk_fix_scale)"

_line() {
  printf '󱙺 Sessão %s%% | Semana %s%% | Sonnet %s%%' "$sess_pct" "$semana_pct" "$sonnet_pct"
}

# Mesmo desenho que claude-oauth-usage.sh --waybar (barrinhas Pango no Waybar)
_color() {
  local pct="${1:-0}"
  pct=$((10#$pct)) 2>/dev/null || pct=0
  (( pct >= 80 )) && echo "#e74c3c" && return
  (( pct >= 60 )) && echo "#f39c12" && return
  echo "#2ecc71"
}

_gauge() {
  local pct="${1:-0}" color num w=4 filled seg i
  pct=$((10#$pct)) 2>/dev/null || pct=0
  (( pct > 100 )) && pct=100
  color=$(_color "$pct")
  (( pct >= 100 )) && num="!!" || num=$(printf '%02d' "$pct")
  filled=$(( pct * w / 100 ))
  (( filled > w )) && filled=$w
  seg=""
  for (( i=0; i<w; i++ )); do (( i < filled )) && seg+="▓" || seg+="░"; done
  printf '<span background="%s" color="#111111">%s</span><span color="%s">%s</span>' \
    "$color" "$num" "$color" "$seg"
}

if [[ "$MODE" == "--waybar" ]]; then
  text="$(_gauge "$sess_pct") $(_gauge "$semana_pct") $(_gauge "$sonnet_pct")"
  tip=$(printf "Sessão %s%% — janela atual\nSemana %s%% — limite semanal\nSonnet %s%% — faixa Sonnet\norg %s" \
    "$sess_pct" "$semana_pct" "$sonnet_pct" "$ORG_ID")
  $JQ -cn --arg text "$text" --arg tooltip "$tip" --arg class '' \
    '{text: $text, tooltip: $tooltip, class: $class}'
  exit 0
fi

if [[ "$MODE" == "--statusline" ]]; then
  printf '%s\n' "$(_line)"
  exit 0
fi

echo "$(_line)"
