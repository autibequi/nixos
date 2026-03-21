# Lista todos os contractors e mostra _schedule/_running
zion_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
CONTRACTORS="${OBSIDIAN}/contractors"

if [ ! -d "$CONTRACTORS" ]; then
  for try in /workspace/obsidian/contractors "$HOME/obsidian/contractors"; do
    [ -d "$try" ] && CONTRACTORS="$try" && break
  done
fi

if [ ! -d "$CONTRACTORS" ]; then
  echo "[contractors] dir nao encontrado"
  exit 1
fi

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; M=$'\033[35m'

ZION_DIR="${ZION_ROOT:-${ZION_NIXOS_DIR:-$HOME/nixos}/zion}"
# Fallback
for try in /workspace/mnt/zion /workspace/nixos/zion; do
  [ -d "$try/agents" ] && ZION_DIR="$try" && break
done

echo ""
echo "${B}${M}  CONTRACTORS${R}"
echo ""

for dir in "$CONTRACTORS"/*/; do
  name=$(basename "$dir")
  [[ "$name" == _* ]] && continue

  # Check if has agent.md (active) or just vault data (archived)
  has_agent=""
  [ -f "$ZION_DIR/agents/$name/agent.md" ] && has_agent=1

  # Count done
  done_count=$(ls "$dir/done/"*.md 2>/dev/null | wc -l | tr -d ' ')

  # Check if has memory
  has_mem=""
  [ -f "$dir/memory.md" ] && has_mem="mem"

  if [ -n "$has_agent" ]; then
    model=$(awk '/^---/{fm++} fm==1 && /^model:/{print $2; exit}' "$ZION_DIR/agents/$name/agent.md" 2>/dev/null)
    printf "  ${G}%-18s${R}  ${DIM}%-8s  done=%-3s  %s${R}\n" "$name" "${model:-?}" "$done_count" "$has_mem"
  else
    printf "  ${DIM}%-18s  archived  done=%-3s  %s${R}\n" "$name" "$done_count" "$has_mem"
  fi
done

# Schedule / Running summary
sched=$(ls "$CONTRACTORS/_schedule/"*.md 2>/dev/null | wc -l | tr -d ' ')
running=$(ls "$CONTRACTORS/_running/"*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "  ${Y}scheduled: ${sched}${R}  ${C}running: ${running}${R}"
echo "  ${DIM}use 'zion contractors status' for details${R}"
echo ""
