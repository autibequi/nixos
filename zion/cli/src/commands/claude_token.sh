# zion claude token — Imprime o OAuth access token do Claude.
# Util para curl manual: TOKEN=$(zion claude token)

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CREDS="${CLAUDE_DIR}/.credentials.json"

if [[ ! -f "$CREDS" ]]; then
  echo "Erro: credenciais não encontradas em $CREDS" >&2
  exit 1
fi

TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS" 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
  echo "Erro: token não encontrado em $CREDS" >&2
  exit 1
fi

echo "$TOKEN"
