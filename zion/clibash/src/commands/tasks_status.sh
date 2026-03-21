# Quick status: counts per column + overdue
zion_load_config

local tasks="${OBSIDIAN_PATH:-$HOME/.ovault/Work}/tasks"

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

todo_count=0
doing_count=0
done_count=0
overdue_count=0
overdue_list=()

# Count TODO + overdue
for card in "$tasks/TODO"/*.md; do
  [ -f "$card" ] || continue
  todo_count=$((todo_count + 1))
  name=$(basename "$card")
  if [[ "$name" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    ts=$(date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0)
    if [ "$ts" -gt 0 ] && [ "$ts" -le "$now" ]; then
      overdue_count=$((overdue_count + 1))
      delta=$(( (now - ts) / 60 ))
      overdue_list+=("${name%.md} (${delta}min ago)")
    fi
  fi
done

# Count DOING
for card in "$tasks/DOING"/*.md; do
  [ -f "$card" ] || continue
  doing_count=$((doing_count + 1))
done

# Count DONE
done_count=$(ls "$tasks/DONE"/*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "${B}  Tasks Status${R}"
echo ""
printf "  ${Y}TODO:  %-4s${R}  ${C}DOING: %-4s${R}  ${G}DONE: %-4s${R}\n" "$todo_count" "$doing_count" "$done_count"

if [ "$overdue_count" -gt 0 ]; then
  echo ""
  echo "  ${RED}Overdue: ${overdue_count}${R}"
  for item in "${overdue_list[@]}"; do
    echo "    ${RED}${item}${R}"
  done
fi

echo ""
