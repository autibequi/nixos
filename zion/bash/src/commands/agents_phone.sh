# Abre uma sessao de conversa com um agente via /meta:phone call
zion_load_config

AGENT="${args[name]:-}"

ZION_DIR="${ZION_ROOT:-${ZION_NIXOS_DIR:-$HOME/nixos}/zion}"
OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"

# Fallback agents dir
for try in /workspace/mnt/zion /workspace/nixos/self; do
  [ -d "$try/agents" ] && ZION_DIR="$try" && break
done

# Lista agentes disponiveis
list_agents() {
  AGENTS_DIR="$ZION_DIR/agents"
  for dir in "$AGENTS_DIR"/*/; do
    name=$(basename "$dir")
    [[ "$name" == _* ]] && continue
    [ -f "$dir/agent.md" ] || continue
    model=$(awk '/^---/{fm++} fm==1 && /^model:/{print $2; exit}' "$dir/agent.md" 2>/dev/null)
    call_style=$(awk '/^---/{fm++} fm==1 && /^call_style:/{print $2; exit}' "$dir/agent.md" 2>/dev/null)
    call_style="${call_style:-phone}"
    printf "  %-16s  %-8s  %s\n" "$name" "${model:-?}" "$call_style"
  done
}

if [ -z "$AGENT" ]; then
  echo ""
  echo "  Agentes disponíveis:"
  echo ""
  list_agents
  echo ""
  echo "  Uso: zion agents phone <nome>"
  echo "  Dentro do Claude Code: /meta:phone call <nome>"
  echo ""
  exit 0
fi

# Verificar se agente existe
AGENT_FILE="$ZION_DIR/agents/${AGENT}/agent.md"
if [ ! -f "$AGENT_FILE" ]; then
  echo "Agente '${AGENT}' nao encontrado."
  echo ""
  list_agents
  exit 1
fi

CALL_STYLE=$(awk '/^---/{fm++} fm==1 && /^call_style:/{print $2; exit}' "$AGENT_FILE" 2>/dev/null)
CALL_STYLE="${CALL_STYLE:-phone}"

echo ""
if [ "$CALL_STYLE" = "personal" ]; then
  echo "  Convocando ${AGENT}..."
  echo ""
else
  echo "  Ligando para ${AGENT}..."
  echo ""
  echo "    bip...    bip...    bip..."
  echo ""
fi

echo "  Abrindo sessao. Na sessao, use:"
echo "    /meta:phone call ${AGENT}"
echo ""

exec zion lab
