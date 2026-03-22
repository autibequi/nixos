#!/usr/bin/env bash
# claude-ai-usage.sh — Uso do plano via API web do claude.ai (mesma fonte da tela Settings > Uso).
# Requer: sessionKey do cookie (login no claude.ai no browser).
# Ordem de leitura: CLAUDE_AI_SESSION_KEY (env) → ~/.claude/claude-ai-session → ~/.config/claude-ai-session
# Arquivo: uma linha com o valor do cookie sessionKey — chmod 600.
# Org ID: CLAUDE_AI_ORG_ID (opcional); senão lido de ~/.claude/.credentials.json ou ~/.claude.json (oauthAccount.organizationUuid).
# Saída: uma linha para Waybar (sessão % | semana %) ou JSON se --json.
set -euo pipefail

SESSION_KEY="${CLAUDE_AI_SESSION_KEY:-}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"

# Org ID: env → ~/.claude/.credentials.json → ~/.claude.json (oauthAccount.organizationUuid)
ORG_ID="${CLAUDE_AI_ORG_ID:-}"
if [[ -z "$ORG_ID" ]] && command -v jq &>/dev/null; then
  if [[ -f "${CLAUDE_DIR}/.credentials.json" ]]; then
    ORG_ID=$(jq -r '.organizationUuid // .organization_id // .oauthAccount.organizationUuid // empty' "${CLAUDE_DIR}/.credentials.json" 2>/dev/null)
  fi
  if [[ -z "$ORG_ID" || "$ORG_ID" == "null" ]] && [[ -f "${HOME}/.claude.json" ]]; then
    ORG_ID=$(jq -r '.oauthAccount.organizationUuid // empty' "${HOME}/.claude.json" 2>/dev/null)
  fi
fi
ORG_ID="${ORG_ID:-995ebddd-ab0c-4ef8-aaf1-ad1fee25f624}"

# 1) env 2) ~/.claude/claude-ai-session 3) ~/.claude/.credentials.json (ou credentials.json) 4) ~/.config/...
if [[ -z "$SESSION_KEY" && -f "${CLAUDE_DIR}/claude-ai-session" ]]; then
  SESSION_KEY=$(head -1 "${CLAUDE_DIR}/claude-ai-session")
fi
if [[ -z "$SESSION_KEY" && -f "${CLAUDE_DIR}/.credentials.json" ]] && command -v jq &>/dev/null; then
  SESSION_KEY=$(jq -r '.sessionKey // .session_key // .cookie_session // .session // empty' "${CLAUDE_DIR}/.credentials.json" 2>/dev/null)
  # OAuth: claudeAiOauth.accessToken (Claude Code Team/Max credential)
  if [[ -z "$SESSION_KEY" || "$SESSION_KEY" == "null" ]]; then
    ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "${CLAUDE_DIR}/.credentials.json" 2>/dev/null)
  fi
fi
if [[ -z "$SESSION_KEY" && -z "${ACCESS_TOKEN:-}" && -f "${CLAUDE_DIR}/credentials.json" ]] && command -v jq &>/dev/null; then
  SESSION_KEY=$(jq -r '.sessionKey // .session_key // .cookie_session // .session // empty' "${CLAUDE_DIR}/credentials.json" 2>/dev/null)
  if [[ -z "$SESSION_KEY" || "$SESSION_KEY" == "null" ]]; then
    ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "${CLAUDE_DIR}/credentials.json" 2>/dev/null)
  fi
fi
if [[ -z "$SESSION_KEY" && -f "${HOME}/.config/claude-ai-session" ]]; then
  SESSION_KEY=$(head -1 "${HOME}/.config/claude-ai-session")
fi
[[ -z "$SESSION_KEY" && -z "${ACCESS_TOKEN:-}" ]] && { echo "󱙺 --"; echo "session em CLAUDE_AI_SESSION_KEY ou ${CLAUDE_DIR}/claude-ai-session ou .credentials.json (OAuth)" >&2; exit 0; }

# Build auth headers based on credential type
AUTH_ARGS=()
if [[ -n "${ACCESS_TOKEN:-}" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer ${ACCESS_TOKEN}")
else
  AUTH_ARGS=(--cookie "sessionKey=${SESSION_KEY}")
fi

JSON=$(curl -sS --max-time 10 \
  "https://claude.ai/api/organizations/${ORG_ID}/usage" \
  -H "Accept: application/json" \
  -H "anthropic-client-platform: web_claude_ai" \
  -H "Content-Type: application/json" \
  "${AUTH_ARGS[@]}" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36") || { echo "󱙺 --"; exit 0; }

if [[ "${1:-}" == "--json" ]]; then
  echo "$JSON"
  exit 0
fi

# Debug: ver JSON bruto
if [[ "${1:-}" == "--debug" ]]; then
  echo "$JSON" | jq . 2>/dev/null || echo "$JSON"
  exit 0
fi

# Extrair % usado — API web claude.ai (estrutura pode variar)
sess_pct=$(echo "$JSON" | jq -r '
  .current_session.percentage_used // .currentSession.percentageUsed // .usage.current_session.percentage_used // .session_usage.percentage_used // 0
' 2>/dev/null)
semana_pct=$(echo "$JSON" | jq -r '
  [.weekly_limits[]? // .weeklyLimits[]? // .usage.weekly_limits[]? // .limits[]? // empty]
  | (.[] | select(.name == "all_models" or .name == "allModels" or .identifier == "all_models" or .type == "all")) as $all
  | if $all then ($all.percentage_used // $all.percentageUsed // 0) else 0 end
' 2>/dev/null)
sonnet_pct=$(echo "$JSON" | jq -r '
  [.weekly_limits[]? // .weeklyLimits[]? // .usage.weekly_limits[]? // .limits[]? // empty]
  | (.[] | select(.name == "sonnet" or .identifier == "sonnet" or .type == "sonnet")) as $s
  | if $s then ($s.percentage_used // $s.percentageUsed // 0) else 0 end
' 2>/dev/null)

# Fallback: qualquer limite semanal (primeiro numérico)
if [[ -z "$semana_pct" || "$semana_pct" == "null" ]]; then
  semana_pct=$(echo "$JSON" | jq -r '
    (.weekly_limits[0] // .weeklyLimits[0] // .limits[0] // {}).percentage_used // .percentageUsed // 0
  ' 2>/dev/null)
fi

[[ -z "$sess_pct" || "$sess_pct" == "null" ]] && sess_pct=0
[[ -z "$semana_pct" || "$semana_pct" == "null" ]] && semana_pct=0
[[ -z "$sonnet_pct" || "$sonnet_pct" == "null" ]] && sonnet_pct=0

# Uma linha para Waybar
printf '󱙺 Sessão %s%% | Semana %s%% | Sonnet %s%%\n' "$sess_pct" "$semana_pct" "$sonnet_pct"
