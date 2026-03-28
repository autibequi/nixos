# leech claude token — Imprime o OAuth access token do Claude.
# Util para curl manual: TOKEN=$(leech claude token)

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CREDS="${CLAUDE_DIR}/.credentials.json"

if [[ ! -f "$CREDS" ]]; then
  echo "Erro: credenciais nao encontradas em $CREDS" >&2
  exit 1
fi

# Extrai token sem depender de jq (grep PCRE com fallback sed)
TOKEN=$(grep -oP '"accessToken"\s*:\s*"\K[^"]+' "$CREDS" 2>/dev/null)
[[ -z "$TOKEN" ]] && TOKEN=$(sed -n 's/.*"accessToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CREDS" 2>/dev/null | head -1)

if [[ -z "$TOKEN" ]]; then
  echo "Erro: token nao encontrado em $CREDS" >&2
  exit 1
fi

echo "$TOKEN"
