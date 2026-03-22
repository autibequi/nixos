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


# ── Last tick info ────────────────────────────────────────────────────────────
_tick_info=""
_last_tick=$(journalctl -u zion-tick.service --no-pager -n 1 -o short-iso 2>/dev/null | grep -v "^--\|^Journal\|^Hint" | awk '{print $1}' | grep -E '^[0-9]{4}-' | tail -1)
if [ -n "$_last_tick" ]; then
  _tick_epoch=$(date -d "$_last_tick" +%s 2>/dev/null || echo 0)
  if [ "$_tick_epoch" -gt 0 ]; then
    _diff_tick=$(( $(date +%s) - _tick_epoch ))
    _next_secs=$(( 600 - _diff_tick ))
    if   (( _diff_tick < 60 ));   then _ago="${_diff_tick}s atras"
    elif (( _diff_tick < 3600 )); then _ago="$((_diff_tick/60))min atras"
    else                               _ago="$((_diff_tick/3600))h atras"; fi
    if   (( _next_secs <= 0 ));   then _next="agora"
    elif (( _next_secs < 60 ));   then _next="em ${_next_secs}s"
    else                               _next="em $((_next_secs/60))min"; fi
    _tick_info="  ${DIM}[tick: $_ago | proximo: $_next]${R}"
  fi
fi

echo ""
echo "${B}${C}▸ ACTIVITY LOG${R}${DIM} (ultimas $TAIL | $([ -n "$FILTER" ] && echo "agent=$FILTER" || echo "todos"))${R}${_tick_info}"
echo ""
printf "  ${DIM}%-14s  %-12s  %-9s  %-6s  %-22s  %s${R}\n" "datetime" "agent" "status" "time" "tokens" "card"
echo "  ${DIM}$(printf '─%.0s' {1..92})${R}"

# ── Scheduled (proximos) ──────────────────────────────────────────────────────
SCHEDULE_DIR="$AGENTS/_schedule"
if [ -d "$SCHEDULE_DIR" ]; then
  NOW=$(date +%s)
  _sched_count=0
  while IFS='|' read -r _diff aname when card_label; do
    (( _sched_count >= 10 )) && break
    _sched_count=$(( _sched_count + 1 ))
    if [[ "$when" == atrasado* ]]; then sc="${Y}sched${R}    "
    else                               sc="${C}sched${R}    "; fi
    printf "  %-14s  %-12s  " "$when" "$aname"
    printf "%-17b  " "$sc"
    printf "%-6s  %-22s  %s\n" "--" "--" "$card_label"
  done < <(
    for f in "$SCHEDULE_DIR"/*.md; do
      [ -f "$f" ] || continue
      fname=$(basename "$f")
      [[ "$fname" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]] || continue
      ts=$(TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null) || continue
      diff=$(( ts - NOW ))
      if   (( diff < -86400 )); then when="atrasado $(((-diff)/3600))h"
      elif (( diff < 0 ));      then when="atrasado $(((-diff)/60))min"
      elif (( diff == 0 ));     then when="agora"
      elif (( diff < 3600 ));   then when="em $((diff/60))min"
      elif (( diff < 86400 ));  then when="em $((diff/3600))h$(( (diff%3600)/60 ))min"
      else                           when="em $((diff/86400))d"; fi
      aname=$(awk '/^---/{fm++} fm==1 && /^agent:/{print $2; exit}' "$f" 2>/dev/null)
      [ -z "$aname" ] && aname=$(awk '/^---/{fm++} fm==1 && /^contractor:/{print $2; exit}' "$f" 2>/dev/null)
      [ -z "$aname" ] && aname="?"
      card_label=$(echo "$fname" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//')
      echo "$diff|$aname|$when|$card_label"
    done | sort -t'|' -k1,1n
  )
  if (( _sched_count > 0 )); then
    echo "  ${DIM}$(printf -- '-%.0s' {1..92})${R}"
  fi
fi

# ── Past entries ──────────────────────────────────────────────────────────────
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
