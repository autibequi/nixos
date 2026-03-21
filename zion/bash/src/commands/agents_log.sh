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

ACTIVITY_DIR="$AGENTS/_logs/activity"
FILTER="${args[agent]:-}"
TAIL="${args[--tail]:-30}"

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; RED=$'\033[31m'

# ── MODE: --schedule → running/scheduled view ─────────────────────
if [[ -n "${args[--schedule]:-}" ]]; then
  SCHEDULE="$AGENTS/_schedule"
  RUNNING="$AGENTS/_running"

  _fm() { awk '/^---/{fm++} fm==1 && /^'"$2"':/{print $2; exit}' "$1" 2>/dev/null; }
  _label() { echo "$1" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//'; }
  _ts() {
    [[ "$1" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]] && \
      TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null || echo 0
  }
  _age() {
    local diff=$(( $(date +%s) - $(_ts "$1") ))
    if   (( diff < 3600 ));  then echo "$((diff/60))min atras"
    elif (( diff < 86400 )); then echo "$((diff/3600))h atras"
    else                          echo "$((diff/86400))d atras"; fi
  }
  _agent_of() {
    local a; a=$(_fm "$1" "agent"); [ -z "$a" ] && a=$(_fm "$1" "contractor"); echo "${a:----}"
  }

  echo ""
  RUN=(); for f in "$RUNNING"/*.md; do [ -f "$f" ] && RUN+=("$(basename "$f")"); done
  echo "${B}${C}▸ RUNNING${R} ${DIM}(${#RUN[@]})${R}"
  if [ ${#RUN[@]} -eq 0 ]; then echo "  ${DIM}(nenhum)${R}"; else
    printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "ha"
    for f in "${RUN[@]}"; do printf "  %-30s  %-14s  %s\n" "$(_label "$f")" "$(_agent_of "$RUNNING/$f")" "$(_age "$f")"; done
  fi
  echo ""

  SCHED=(); for f in "$SCHEDULE"/*.md; do [ -f "$f" ] && SCHED+=("$(basename "$f")"); done
  echo "${B}${Y}▸ SCHEDULED${R} ${DIM}(${#SCHED[@]})${R}"
  if [ ${#SCHED[@]} -eq 0 ]; then echo "  ${DIM}(nenhum)${R}"; else
    printf "  ${DIM}%-30s  %-14s  %s${R}\n" "card" "agent" "quando"
    NOW=$(date +%s)
    for f in "${SCHED[@]}"; do
      ts=$(_ts "$f"); diff=$(( ts - NOW ))
      if   (( diff < -60 ));   then when="${G}atrasado $(((-diff)/60))min${R}"
      elif (( diff <= 0 ));    then when="${G}agora${R}"
      elif (( diff < 3600 ));  then when="em $((diff/60))min"
      elif (( diff < 86400 )); then when="em $((diff/3600))h"
      else                          when="em $((diff/86400))d"; fi
      printf "  %-30s  %-14s  " "$(_label "$f")" "$(_agent_of "$SCHEDULE/$f")"
      echo -e "$when"
    done
  fi
  echo ""
  exit 0
fi

# ── MODE: activity log ────────────────────────────────────────────
if [ ! -d "$ACTIVITY_DIR" ]; then
  echo "${DIM}[log] nenhum activity log ainda${R}"
  echo "      Pasta esperada: $ACTIVITY_DIR"
  echo "      Agents geram entradas automaticamente ao rodar."
  exit 0
fi

declare -a LOG_FILES=()
if [ -n "$FILTER" ]; then
  if [ -f "$ACTIVITY_DIR/$FILTER" ]; then
    LOG_FILES=("$ACTIVITY_DIR/$FILTER")
  else
    echo "[log] agent '$FILTER' sem log em $ACTIVITY_DIR"
    echo "Disponiveis: $(ls "$ACTIVITY_DIR" 2>/dev/null | tr '\n' ' ')"
    exit 1
  fi
else
  while IFS= read -r f; do [ -f "$f" ] && LOG_FILES+=("$f"); done < <(ls "$ACTIVITY_DIR"/ 2>/dev/null | xargs -I{} echo "$ACTIVITY_DIR/{}")
fi

if [ ${#LOG_FILES[@]} -eq 0 ]; then
  echo "${DIM}(nenhuma entrada ainda)${R}"
  exit 0
fi

MERGED=$(cat "${LOG_FILES[@]}" 2>/dev/null | sort -r | head -"$TAIL")

if [ -z "$MERGED" ]; then
  echo "${DIM}(nenhuma entrada ainda)${R}"
  exit 0
fi

echo ""
echo "${B}${C}▸ ACTIVITY LOG${R}${DIM} (ultimas $TAIL | $([ -n "$FILTER" ] && echo "agent=$FILTER" || echo "todos"))${R}"
echo ""
printf "  ${DIM}%-14s  %-12s  %-9s  %-6s  %-22s  %s${R}\n" "datetime" "agent" "status" "time" "tokens" "card"
echo "  ${DIM}$(printf '─%.0s' {1..92})${R}"

while IFS=$'\t' read -r ts agent status elapsed tokens card; do
  case "$status" in
    ok)      sc="${G}ok${R}      " ;;
    timeout) sc="${Y}timeout${R} " ;;
    fail)    sc="${RED}fail${R}    " ;;
    *)       sc="${DIM}${status:-?}${R}" ;;
  esac
  ts_short=$(echo "$ts" | sed 's/[0-9]\{4\}-\([0-9]\{2\}\)-\([0-9]\{2\}\)T\([0-9]\{2\}:[0-9]\{2\}\).*/\1-\2 \3Z/')
  card_short=$(echo "$card" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//')
  printf "  %-14s  %-12s  " "$ts_short" "$agent"
  printf "%-17b  " "$sc"
  printf "%-6s  %-22s  %s\n" "$elapsed" "${tokens:-—}" "$card_short"
done <<< "$MERGED"

echo ""

# Resumo por agent (últimas 24h)
if [ -z "$FILTER" ] && [ ${#LOG_FILES[@]} -gt 1 ]; then
  cutoff=$(date -u -d "24 hours ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "0000")
  echo "${B}${DIM}▸ ultimas 24h por agent${R}"
  printf "  ${DIM}%-14s  %5s  %5s  %5s${R}\n" "agent" "ok" "fail" "total"
  for logf in "${LOG_FILES[@]}"; do
    aname=$(basename "$logf")
    recent=$(awk -v cut="$cutoff" -F'\t' '$1 >= cut' "$logf" 2>/dev/null || true)
    [ -z "$recent" ] && continue
    ok_c=$(echo "$recent" | grep -c $'\tok\t' 2>/dev/null || echo 0)
    fail_c=$(echo "$recent" | grep -cE $'\t(fail|timeout)\t' 2>/dev/null || echo 0)
    total=$(echo "$recent" | grep -c . 2>/dev/null || echo 0)
    [ "$total" -gt 0 ] && printf "  %-14s  %5s  %5s  %5s\n" "$aname" "$ok_c" "$fail_c" "$total"
  done
  echo ""
fi
