# List task cards in TODO/DOING/DONE
zion_load_config

local show_all="${args[--all]:-}"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local tasks="$obsidian/tasks"

# Fallback paths
if [ ! -d "$tasks" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

if [ ! -d "$tasks" ]; then
  echo "[tasks] dir not found"
  exit 1
fi

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; RED=$'\033[31m'

now=$(date +%s)

# Helper: parse timestamp from filename
_card_epoch() {
  local name="$1"
  if [[ "$name" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

echo ""

# DOING
doing_count=0
echo "${B}${C}  DOING${R}"
for card in "$tasks/DOING"/*.md; do
  [ -f "$card" ] || continue
  doing_count=$((doing_count + 1))
  name=$(basename "$card" .md)
  ts=$(_card_epoch "$name")
  if [ "$ts" -gt 0 ]; then
    elapsed=$(( (now - ts) / 60 ))
    printf "  ${C}%-50s${R}  ${DIM}%+dmin${R}\n" "$name" "$elapsed"
  else
    printf "  ${C}%s${R}\n" "$name"
  fi
done
[ "$doing_count" -eq 0 ] && echo "  ${DIM}(empty)${R}"
echo ""

# TODO
todo_count=0
overdue_count=0
echo "${B}${Y}  TODO${R}"
for card in "$tasks/TODO"/*.md; do
  [ -f "$card" ] || continue
  todo_count=$((todo_count + 1))
  name=$(basename "$card" .md)
  ts=$(_card_epoch "$name")
  if [ "$ts" -gt 0 ]; then
    delta=$(( (ts - now) / 60 ))
    if [ "$delta" -lt 0 ]; then
      overdue_count=$((overdue_count + 1))
      printf "  ${RED}%-50s  %+dmin (overdue)${R}\n" "$name" "$delta"
    else
      printf "  ${Y}%-50s${R}  ${DIM}in %dmin${R}\n" "$name" "$delta"
    fi
  else
    printf "  ${Y}%s${R}\n" "$name"
  fi
done
[ "$todo_count" -eq 0 ] && echo "  ${DIM}(empty)${R}"
echo ""

# DONE (optional)
if [ -n "$show_all" ]; then
  echo "${B}${G}  DONE (last 20)${R}"
  ls -t "$tasks/DONE"/*.md 2>/dev/null | head -20 | while read f; do
    printf "  ${DIM}%s${R}\n" "$(basename "$f" .md)"
  done
  echo ""
fi

# Summary
done_count=$(ls "$tasks/DONE"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  ${Y}todo: ${todo_count}${R}  ${C}doing: ${doing_count}${R}  ${G}done: ${done_count}${R}"
[ "$overdue_count" -gt 0 ] && echo "  ${RED}overdue: ${overdue_count}${R}"
echo ""
