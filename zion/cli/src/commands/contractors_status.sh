# Lista contractor cards: TODO, DOING e últimas 10 DONE
zion_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
TASKS="${TASK_DIR:-$OBSIDIAN/tasks}"

if [ ! -d "$TASKS" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && TASKS="$try" && break
  done
fi

if [ ! -d "$TASKS" ]; then
  echo "[status] tasks dir nao encontrado"
  exit 1
fi

_fm() {
  local file="$1" key="$2"
  awk '/^---/{fm++} fm==1 && /^'"$key"':/{print $2; exit}' "$file" 2>/dev/null
}

_label() {
  echo "$1" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//'
}

_ts() {
  local f="$1"
  if [[ "$f" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

_age() {
  local diff=$(( $(date +%s) - $(_ts "$1") ))
  if   (( diff < 3600 ));  then echo "$((diff/60))min atrás"
  elif (( diff < 86400 )); then echo "$((diff/3600))h atrás"
  else                          echo "$((diff/86400))d atrás"
  fi
}

_agent() {
  local path="$1"
  local a
  a=$(_fm "$path" "contractor")
  [ -z "$a" ] && a=$(_fm "$path" "agent")
  echo "${a:-—}"
}

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'

echo ""

# ── DOING ──────────────────────────────────────────────────────
DOING=()
for f in "$TASKS/DOING"/*.md; do [ -f "$f" ] && DOING+=("$(basename "$f")"); done

echo "${B}${C}▸ DOING${R} ${DIM}(${#DOING[@]})${R}"
if [ ${#DOING[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhum)${R}"
else
  printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "há"
  for f in "${DOING[@]}"; do
    printf "  %-30s  %-14s  %s\n" "$(_label "$f")" "$(_agent "$TASKS/DOING/$f")" "$(_age "$f")"
  done
fi
echo ""

# ── TODO ───────────────────────────────────────────────────────
TODO=()
for f in "$TASKS/TODO"/*.md; do [ -f "$f" ] && TODO+=("$(basename "$f")"); done

echo "${B}${Y}▸ TODO${R} ${DIM}(${#TODO[@]})${R}"
if [ ${#TODO[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhum)${R}"
else
  printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "quando"
  NOW=$(date +%s)
  for f in "${TODO[@]}"; do
    ts=$(_ts "$f")
    diff=$(( ts - NOW ))
    if   (( diff < -60 ));   then when="${G}atrasado $(((-diff)/60))min${R}"
    elif (( diff <= 0 ));    then when="${G}agora${R}"
    elif (( diff < 3600 ));  then when="em $((diff/60))min"
    elif (( diff < 86400 )); then when="em $((diff/3600))h"
    else                          when="em $((diff/86400))d"
    fi
    printf "  %-30s  %-14s  " "$(_label "$f")" "$(_agent "$TASKS/TODO/$f")"
    echo -e "$when"
  done
fi
echo ""

# ── DONE (últimas 10) ──────────────────────────────────────────
DONE=()
while IFS= read -r f; do DONE+=("$f"); done < <(
  ls -1t "$TASKS/DONE"/*.md 2>/dev/null | head -10 | xargs -I{} basename {}
)

echo "${B}${DIM}▸ DONE${R} ${DIM}(últimas ${#DONE[@]})${R}"
if [ ${#DONE[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhuma)${R}"
else
  printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "concluído"
  for f in "${DONE[@]}"; do
    printf "  %-30s  %-14s  %s\n" "$(_label "$f")" "$(_agent "$TASKS/DONE/$f")" "$(_age "$f")"
  done
fi
echo ""
