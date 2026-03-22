# Dashboard live: tasks kanban + agents activity + schedule
leech_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
TASKS_DIR="$OBSIDIAN/tasks"
AGENTS_DIR="$OBSIDIAN/agents"
ACTIVITY_DIR="$AGENTS_DIR/_logs/activity"

for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
  [ ! -d "$TASKS_DIR" ] && [ -d "$try" ] && TASKS_DIR="$try"
done
for try in /workspace/obsidian/agents "$HOME/obsidian/agents"; do
  [ ! -d "$AGENTS_DIR" ] && [ -d "$try" ] && AGENTS_DIR="$try" && ACTIVITY_DIR="$try/_logs/activity"
done

TICK="${args[--tick]:-5}"

R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; RED=$'\033[31m'; M=$'\033[35m'

_ts_epoch() {
  local f="$1"
  [[ "$f" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]] && \
    TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0
}
_label() { echo "$1" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//'; }
_age() {
  local diff=$(( $(date +%s) - $1 ))
  if   (( diff < 60 ));    then echo "${diff}s"
  elif (( diff < 3600 ));  then echo "$((diff/60))min"
  elif (( diff < 86400 )); then echo "$((diff/3600))h"
  else                          echo "$((diff/86400))d"; fi
}
_eta() {
  local diff=$(( $1 - $(date +%s) ))
  if   (( diff < -86400 )); then echo "${RED}$(((-diff)/3600))h atras${R}"
  elif (( diff < -60 ));    then echo "${Y}$(((-diff)/60))min atras${R}"
  elif (( diff <= 0 ));     then echo "${G}agora${R}"
  elif (( diff < 3600 ));   then echo "em $((diff/60))min"
  elif (( diff < 86400 ));  then echo "em $((diff/3600))h"
  else                           echo "em $((diff/86400))d"; fi
}

_render() {
  local NOW=$(date +%s)
  local cols=$(tput cols 2>/dev/null || echo 120)

  printf '\033[H\033[2J'  # clear screen

  # ── Header ──────────────────────────────────────────────────────
  local ts_now=$(date -u +"%H:%M:%S UTC")
  printf "${B}${C}  LEECH TASKS DASHBOARD${R}  ${DIM}%s  (refresh: %ss  q=sair)${R}\n" "$ts_now" "$TICK"
  printf "${DIM}%*s${R}\n" "$cols" "" | tr ' ' '─'

  # ── DOING ───────────────────────────────────────────────────────
  local DOING=(); for f in "$TASKS_DIR/DOING"/*.md; do [ -f "$f" ] && DOING+=("$(basename "$f")"); done
  printf "\n  ${B}${Y}DOING${R}  ${DIM}(%d)${R}\n" "${#DOING[@]}"
  if [ ${#DOING[@]} -eq 0 ]; then
    printf "  ${DIM}(nenhuma)${R}\n"
  else
    printf "  ${DIM}%-45s  %s${R}\n" "task" "ha"
    for f in "${DOING[@]}"; do
      ts=$(_ts_epoch "$f")
      printf "  ${Y}●${R} %-45s  %s\n" "$(_label "$f")" "$(_age "$ts")"
    done
  fi

  # ── TODO ────────────────────────────────────────────────────────
  local TODO=(); for f in "$TASKS_DIR/TODO"/*.md; do [ -f "$f" ] && TODO+=("$(basename "$f")"); done
  IFS=$'\n' TODO=($(printf '%s\n' "${TODO[@]}" | sort 2>/dev/null)); unset IFS
  printf "\n  ${B}${C}TODO${R}  ${DIM}(%d total)${R}\n" "${#TODO[@]}"
  if [ ${#TODO[@]} -eq 0 ]; then
    printf "  ${DIM}(nenhuma)${R}\n"
  else
    printf "  ${DIM}%-45s  %s${R}\n" "task" "quando"
    local count=0
    for f in "${TODO[@]}"; do
      [ "$count" -ge 8 ] && break
      ts=$(_ts_epoch "$f")
      printf "  ${C}○${R} %-45s  " "$(_label "$f")"
      echo -e "$(_eta "$ts")"
      count=$((count+1))
    done
    [ "${#TODO[@]}" -gt 8 ] && printf "  ${DIM}... +%d mais${R}\n" $(( ${#TODO[@]} - 8 ))
  fi

  # ── DONE recentes ───────────────────────────────────────────────
  local DONE=(); while IFS= read -r f; do [ -n "$f" ] && DONE+=("$f"); done < <(
    ls -1t "$TASKS_DIR/DONE"/*.md 2>/dev/null | head -5
  )
  printf "\n  ${B}${DIM}DONE${R}  ${DIM}(ultimas %d)${R}\n" "${#DONE[@]}"
  if [ ${#DONE[@]} -eq 0 ]; then
    printf "  ${DIM}(nenhuma)${R}\n"
  else
    for fpath in "${DONE[@]}"; do
      f=$(basename "$fpath"); ts=$(_ts_epoch "$f")
      printf "  ${DIM}✓${R} ${DIM}%-45s  %s${R}\n" "$(_label "$f")" "$(_age "$ts")"
    done
  fi

  printf "\n  ${DIM}%*s${R}\n" "$cols" "" | tr ' ' '─'

  # ── AGENTS SCHEDULE (proximos 8) ────────────────────────────────
  local SCHED_DIR="$AGENTS_DIR/_schedule"
  printf "\n  ${B}${M}AGENTS SCHEDULE${R}\n"
  if [ ! -d "$SCHED_DIR" ]; then
    printf "  ${DIM}(nao encontrado)${R}\n"
  else
    printf "  ${DIM}%-14s  %-12s  %s${R}\n" "agent" "quando" "card"
    local scount=0
    while IFS='|' read -r diff aname when card_label; do
      (( scount >= 8 )) && break
      scount=$((scount+1))
      if [[ "$when" == atrasado* ]]; then color="$Y"
      else color="$R"; fi
      printf "  ${M}·${R} %-14s  ${color}%-12s${R}  %s\n" "$aname" "$when" "$card_label"
    done < <(
      for f in "$SCHED_DIR"/*.md; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        [[ "$fname" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]] || continue
        ts=$(TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null) || continue
        diff=$(( ts - NOW ))
        if   (( diff < -86400 )); then when="atrasado $(((-diff)/3600))h"
        elif (( diff < 0 ));      then when="atrasado $(((-diff)/60))min"
        elif (( diff == 0 ));     then when="agora"
        elif (( diff < 3600 ));   then when="em $((diff/60))min"
        elif (( diff < 86400 ));  then when="em $((diff/3600))h"
        else                           when="em $((diff/86400))d"; fi
        aname=$(awk '/^---/{fm++} fm==1 && /^(agent|contractor):/{print $2; exit}' "$f" 2>/dev/null)
        [ -z "$aname" ] && aname="?"
        card_label=$(echo "$fname" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//')
        echo "$diff|$aname|$when|$card_label"
      done | sort -t'|' -k1,1n
    )
  fi

  # ── ACTIVITY (ultimas 10 runs) ──────────────────────────────────
  printf "\n  ${B}${DIM}ACTIVITY RECENTE${R}\n"
  if [ ! -d "$ACTIVITY_DIR" ]; then
    printf "  ${DIM}(sem logs ainda)${R}\n"
  else
    local MERGED
    MERGED=$(cat "$ACTIVITY_DIR"/* 2>/dev/null | sort -r | head -10)
    if [ -z "$MERGED" ]; then
      printf "  ${DIM}(sem entradas)${R}\n"
    else
      printf "  ${DIM}%-14s  %-10s  %-8s  %-6s  %s${R}\n" "datetime" "agent" "status" "time" "tokens"
      while IFS=$'\t' read -r ts agent status elapsed tokens _card; do
        case "$status" in
          ok)       sc="${G}ok${R}     " ;;
          migrated) sc="${DIM}migr${R}   "; continue ;;
          timeout)  sc="${Y}timeout${R}" ;;
          fail)     sc="${RED}fail${R}   " ;;
          *)        continue ;;
        esac
        ts_s=$(echo "$ts" | sed 's/[0-9]\{4\}-\([0-9]\{2\}\)-\([0-9]\{2\}\)T\([0-9]\{2\}:[0-9]\{2\}\).*/\1-\2 \3Z/')
        printf "  %-14s  %-10s  " "$ts_s" "$agent"
        printf "%-16b  " "$sc"
        printf "%-6s  %s\n" "$elapsed" "${tokens:-—}"
      done <<< "$MERGED"
    fi
  fi

  # ── Footer ──────────────────────────────────────────────────────
  printf "\n  ${DIM}%*s${R}\n" "$cols" "" | tr ' ' '─'
  printf "  ${DIM}leech tasker${R} — lanca tasker agora    ${DIM}leech tick${R} — roda todos os agents\n"
  printf '\033[?25l'  # hide cursor
}

# ── Main loop ─────────────────────────────────────────────────────
printf '\033[?1049h'  # alternate screen
trap 'printf "\033[?1049l\033[?25h"; exit 0' INT TERM EXIT

while true; do
  _render
  # Wait with keypress detection
  if read -r -s -n 1 -t "$TICK" key 2>/dev/null; then
    [[ "$key" == "q" || "$key" == "Q" ]] && break
  fi
done
