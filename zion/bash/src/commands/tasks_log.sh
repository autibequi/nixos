# Ultimas execucoes de tasks: DOING + DONE recentes
zion_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
TASKS="$OBSIDIAN/tasks"

if [ ! -d "$TASKS" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && TASKS="$try" && break
  done
fi

if [ ! -d "$TASKS" ]; then
  echo "[tasks] dir nao encontrado"
  exit 1
fi

_ts() {
  local f="$1"
  if [[ "$f" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]]; then
    TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0
  else
    echo 0
  fi
}

_label() {
  echo "$1" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//'
}

_age() {
  local diff=$(( $(date +%s) - $(_ts "$1") ))
  if   (( diff < 3600 ));  then echo "$((diff/60))min atras"
  elif (( diff < 86400 )); then echo "$((diff/3600))h atras"
  else                          echo "$((diff/86400))d atras"
  fi
}

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
Y=$'\033[33m'; G=$'\033[32m'; C=$'\033[36m'

echo ""

# ── DOING ──────────────────────────────────────────────────────
DOING=()
for f in "$TASKS/DOING"/*.md; do [ -f "$f" ] && DOING+=("$(basename "$f")"); done

echo "${B}${Y}▸ DOING${R} ${DIM}(${#DOING[@]})${R}"
if [ ${#DOING[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhuma)${R}"
else
  printf "  ${DIM}%-50s  %s${R}\n" "task" "ha"
  for f in "${DOING[@]}"; do
    printf "  %-50s  %s\n" "$(_label "$f")" "$(_age "$f")"
  done
fi
echo ""

# ── TODO (proximas 10) ─────────────────────────────────────────
TODO=()
for f in "$TASKS/TODO"/*.md; do [ -f "$f" ] && TODO+=("$(basename "$f")"); done
# Sort by name (timestamp prefix = chronological)
IFS=$'\n' TODO=($(printf '%s\n' "${TODO[@]}" | sort)); unset IFS

echo "${B}${C}▸ TODO${R} ${DIM}(${#TODO[@]} total, proximas 10)${R}"
if [ ${#TODO[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhuma)${R}"
else
  NOW=$(date +%s)
  count=0
  for f in "${TODO[@]}"; do
    [ "$count" -ge 10 ] && break
    ts=$(_ts "$f")
    diff=$(( ts - NOW ))
    if   (( diff < -60 ));   then when="${G}atrasada $(((-diff)/60))min${R}"
    elif (( diff <= 0 ));    then when="${G}agora${R}"
    elif (( diff < 3600 ));  then when="em $((diff/60))min"
    elif (( diff < 86400 )); then when="em $((diff/3600))h"
    else                          when="em $((diff/86400))d"
    fi
    printf "  %-50s  " "$(_label "$f")"
    echo -e "$when"
    count=$((count + 1))
  done
fi
echo ""

# ── DONE (ultimas 15) ──────────────────────────────────────────
DONE=()
if [ -d "$TASKS/DONE" ]; then
  while IFS= read -r f; do [ -n "$f" ] && DONE+=("$(basename "$f")"); done < <(
    ls -1t "$TASKS/DONE"/*.md 2>/dev/null | head -15
  )
fi

echo "${B}${DIM}▸ DONE${R} ${DIM}(ultimas ${#DONE[@]})${R}"
if [ ${#DONE[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhuma)${R}"
else
  for f in "${DONE[@]}"; do
    printf "  %-50s  %s\n" "$(_label "$f")" "$(_age "$f")"
  done
fi
echo ""
