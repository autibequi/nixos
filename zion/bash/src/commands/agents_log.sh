# Lista execucoes de agents: _schedule, _running e done recentes
zion_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
AGENTS="${OBSIDIAN}/agents"

if [ ! -d "$AGENTS" ]; then
  for try in /workspace/obsidian/agents "$HOME/obsidian/agents"; do
    [ -d "$try" ] && AGENTS="$try" && break
  done
fi

if [ ! -d "$AGENTS" ]; then
  echo "[log] agents dir nao encontrado"
  exit 1
fi

SCHEDULE="$AGENTS/_schedule"
RUNNING="$AGENTS/_running"

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
  if   (( diff < 3600 ));  then echo "$((diff/60))min atras"
  elif (( diff < 86400 )); then echo "$((diff/3600))h atras"
  else                          echo "$((diff/86400))d atras"
  fi
}

_agent() {
  local path="$1"
  local a
  a=$(_fm "$path" "agent")
  [ -z "$a" ] && a=$(_fm "$path" "contractor")
  echo "${a:----}"
}

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'

echo ""

# ── RUNNING ──────────────────────────────────────────────────
RUN=()
for f in "$RUNNING"/*.md; do [ -f "$f" ] && RUN+=("$(basename "$f")"); done

echo "${B}${C}▸ RUNNING${R} ${DIM}(${#RUN[@]})${R}"
if [ ${#RUN[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhum)${R}"
else
  printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "ha"
  for f in "${RUN[@]}"; do
    printf "  %-30s  %-14s  %s\n" "$(_label "$f")" "$(_agent "$RUNNING/$f")" "$(_age "$f")"
  done
fi
echo ""

# ── SCHEDULED ────────────────────────────────────────────────
SCHED=()
for f in "$SCHEDULE"/*.md; do [ -f "$f" ] && SCHED+=("$(basename "$f")"); done

echo "${B}${Y}▸ SCHEDULED${R} ${DIM}(${#SCHED[@]})${R}"
if [ ${#SCHED[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhum)${R}"
else
  printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "quando"
  NOW=$(date +%s)
  for f in "${SCHED[@]}"; do
    ts=$(_ts "$f")
    diff=$(( ts - NOW ))
    if   (( diff < -60 ));   then when="${G}atrasado $(((-diff)/60))min${R}"
    elif (( diff <= 0 ));    then when="${G}agora${R}"
    elif (( diff < 3600 ));  then when="em $((diff/60))min"
    elif (( diff < 86400 )); then when="em $((diff/3600))h"
    else                          when="em $((diff/86400))d"
    fi
    printf "  %-30s  %-14s  " "$(_label "$f")" "$(_agent "$SCHEDULE/$f")"
    echo -e "$when"
  done
fi
echo ""

# ── DONE (últimas 10, todos os agents) ──────────────────
DONE=()
while IFS= read -r f; do [ -n "$f" ] && DONE+=("$f"); done < <(
  ls -1t "$AGENTS"/*/done/*.md 2>/dev/null | head -10
)

echo "${B}${DIM}▸ DONE${R} ${DIM}(ultimas ${#DONE[@]})${R}"
if [ ${#DONE[@]} -eq 0 ]; then
  echo "  ${DIM}(nenhuma)${R}"
else
  printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "concluido"
  for fpath in "${DONE[@]}"; do
    f=$(basename "$fpath")
    agent=$(basename "$(dirname "$(dirname "$fpath")")")
    printf "  %-30s  %-14s  %s\n" "$(_label "$f")" "$agent" "$(_age "$f")"
  done
fi
echo ""
