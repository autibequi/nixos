# Lista todos os agentes e mostra _schedule/_running
zion_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
AGENTS="${OBSIDIAN}/agents"

if [ ! -d "$AGENTS" ]; then
  for try in /workspace/obsidian/agents "$HOME/obsidian/agents"; do
    [ -d "$try" ] && AGENTS="$try" && break
  done
fi

if [ ! -d "$AGENTS" ]; then
  echo "[agents] dir nao encontrado"
  exit 1
fi

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; M=$'\033[35m'

ZION_DIR="${ZION_ROOT:-${ZION_NIXOS_DIR:-$HOME/nixos}/self}"
# Fallback
for try in /workspace/mnt/self /workspace/nixos/self; do
  [ -d "$try/agents" ] && ZION_DIR="$try" && break
done

echo ""
echo "${B}${M}  AGENTS${R}"
echo ""

for dir in "$AGENTS"/*/; do
  name=$(basename "$dir")
  [[ "$name" == _* ]] && continue

  has_agent=""
  [ -f "$ZION_DIR/agents/$name/agent.md" ] && has_agent=1

  done_count=$(ls "$dir/done/"*.md 2>/dev/null | wc -l | tr -d ' ')

  has_mem=""
  [ -f "$dir/memory.md" ] && has_mem="mem"

  if [ -n "$has_agent" ]; then
    model=$(awk '/^---/{fm++} fm==1 && /^model:/{print $2; exit}' "$ZION_DIR/agents/$name/agent.md" 2>/dev/null)
    call_style=$(awk '/^---/{fm++} fm==1 && /^call_style:/{print $2; exit}' "$ZION_DIR/agents/$name/agent.md" 2>/dev/null)
    call_style="${call_style:-phone}"
    printf "  ${G}%-18s${R}  ${DIM}%-8s  done=%-3s  %-8s  %s${R}\n" "$name" "${model:-?}" "$done_count" "$call_style" "$has_mem"
  else
    printf "  ${DIM}%-18s  archived  done=%-3s  %s${R}\n" "$name" "$done_count" "$has_mem"
  fi
done

# Schedule / Running summary
sched=$(ls "$AGENTS/_schedule/"*.md 2>/dev/null | wc -l | tr -d ' ')
running=$(ls "$AGENTS/_running/"*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "  ${Y}scheduled: ${sched}${R}  ${C}running: ${running}${R}"
echo "  ${DIM}zion agents log  — detalhes de execucao${R}"
echo "  ${DIM}zion agents phone <nome>  — conversar com um agente${R}"
echo ""
