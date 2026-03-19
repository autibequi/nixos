# zion claude token — Imprime o OAuth access token do Claude.
# Util para curl manual: TOKEN=$(zion claude token)

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CREDS="${CLAUDE_DIR}/.credentials.json"

if [[ ! -f "$CREDS" ]]; then
  echo "Erro: credenciais nao encontradas em $CREDS" >&2
  exit 1
fi

JQ_BIN=""
for _p in jq /run/current-system/sw/bin/jq "${HOME}/.nix-profile/bin/jq" /usr/bin/jq; do
  command -v "$_p" &>/dev/null && JQ_BIN="$_p" && break
  [[ -x "$_p" ]] && JQ_BIN="$_p" && break
done
if [[ -z "$JQ_BIN" ]]; then
  echo "Erro: jq nao encontrado" >&2; exit 1
fi

TOKEN=$("$JQ_BIN" -r '.claudeAiOauth.accessToken // empty' "$CREDS" 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
  echo "Erro: token nao encontrado em $CREDS" >&2
  exit 1
fi

echo "$TOKEN"
