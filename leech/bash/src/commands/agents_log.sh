leech_load_config

OBSIDIAN="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
# Resolve obsidian dir (host vs container)
_resolve_obsidian() {
  local t
  for t in "$1" /workspace/obsidian "$HOME/.ovault/Work"; do
    [ -d "$t/tasks" ] && echo "$t" && return
  done
  echo "$1"
}
OBSIDIAN="$(_resolve_obsidian "$OBSIDIAN")"

AGENTS_SCHEDULE="$OBSIDIAN/tasks/AGENTS"
AGENTS_RUNNING="$OBSIDIAN/tasks/AGENTS/DOING"
BEDROOMS="$OBSIDIAN/bedrooms"
ACTIVITY_LOG="$OBSIDIAN/vault/logs/agents.md"

if [ ! -d "$OBSIDIAN/tasks" ]; then
  echo "[log] obsidian tasks dir nao encontrado ($OBSIDIAN/tasks)"
  exit 1
fi
FILTER="${args[agent]:-}"
TAIL="${args[--tail]:-30}"

B=$'\033[1m'; R=$'\033[0m'; DIM=$'\033[2m'
G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; RED=$'\033[31m'

# ── MODE: --schedule → running/scheduled view ─────────────────────
if [[ -n "${args[--schedule]:-}" ]]; then
  SCHEDULE="$AGENTS_SCHEDULE"
  RUNNING="$AGENTS_RUNNING"

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
if [ ! -f "$ACTIVITY_LOG" ]; then
  echo "${DIM}[log] nenhum activity log ainda${R}"
  echo "      Esperado: $ACTIVITY_LOG"
  exit 0
fi

# Parse markdown table: | Timestamp | Agente | Status | Duracao | Tokens | Card |
# Filter by agent if requested, take last N entries
if [ -n "$FILTER" ]; then
  MERGED=$(grep "^|" "$ACTIVITY_LOG" | grep -v "^| Timestamp\|^|---" | grep "| $FILTER |" | tail -"$TAIL" | tac)
else
  MERGED=$(grep "^|" "$ACTIVITY_LOG" | grep -v "^| Timestamp\|^|---" | tail -"$TAIL" | tac)
fi

if [ -z "$MERGED" ]; then
  echo "${DIM}(nenhuma entrada ainda)${R}"
  exit 0
fi

# ── Last tick info ────────────────────────────────────────────────
_tick_info=""
_last_tick=$(journalctl -u leech-tick.service --no-pager -n 1 -o short-iso 2>/dev/null | grep -v "^--\|^Journal\|^Hint" | awk '{print $1}' | grep -E '^[0-9]{4}-' | tail -1)
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

_filter_hint="todos"
[ -n "$FILTER" ] && _filter_hint="agent=$FILTER"
echo ""
echo "${B}${C}▸ ACTIVITY LOG${R}${DIM} (ultimas $TAIL | ${_filter_hint})${R}${_tick_info}"
echo ""
printf "  ${DIM}%-14s  %-8s  %-12s  %-4s  %s${R}\n" "starttime" "duration" "agent" "st" "topic"
echo "  ${DIM}$(printf '─%.0s' {1..80})${R}"

# ── Queue: running + scheduled (proximos 10) ──────────────────────
NOW=$(date +%s)
_queue_output=$({
  for dir_state in "$AGENTS_RUNNING:running" "$AGENTS_SCHEDULE:sched"; do
    dir="${dir_state%%:*}"; state="${dir_state##*:}"
    [ -d "$dir" ] || continue
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      fname=$(basename "$f")
      [[ "$fname" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]] || continue
      ts=$(TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null) || continue
      ts_display=$(date -d "@$ts" +"%m-%d %H:%M")
      aname=$(awk '/^---/{fm++} fm==1 && /^agent:/{print $2; exit}' "$f" 2>/dev/null)
      [ -z "$aname" ] && aname=$(awk '/^---/{fm++} fm==1 && /^contractor:/{print $2; exit}' "$f" 2>/dev/null)
      [ -z "$aname" ] && aname="?"
      card_label=$(echo "$fname" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//')
      echo "$ts|$ts_display|$aname|$card_label|$state"
    done
  done
} | sort -t'|' -k1,1rn | head -10)

if [ -n "$_queue_output" ]; then
  while IFS='|' read -r _ts ts_display aname card_label state; do
    diff=$(( _ts - NOW ))
    if [ "$state" = "running" ] || (( diff < 0 )); then
      # Overdue or stuck running → red
      printf "  ${RED}%-14s${R}  %-8s  %-12s  " "$ts_display" "--" "$aname"
      printf "${RED}!!${R}   "
    else
      # Future → cyan
      printf "  ${C}%-14s${R}  %-8s  %-12s  " "$ts_display" "--" "$aname"
      printf "${C}..${R}   "
    fi
    printf "%s\n" "$card_label"
  done <<< "$_queue_output"
fi

# ── NOW line ──────────────────────────────────────────────────────
_now_display=$(date +"%m-%d %H:%M")
printf "  ${Y}%-14s  %-8s  %-12s  %-4s  %s${R}\n" "$_now_display" "now" "─────" "──" "──────"

# ── Past entries (from markdown table) ───────────────────────────
while IFS='|' read -r _ ts agent status dur tokens card _; do
  # Trim whitespace
  ts="${ts## }"; ts="${ts%% }"
  agent="${agent## }"; agent="${agent%% }"
  status="${status## }"; status="${status%% }"
  dur="${dur## }"; dur="${dur%% }"
  card="${card## }"; card="${card%% }"

  [ -z "$ts" ] && continue

  # Status icon
  case "$status" in
    ok)       sc="${G}ok${R} " ;;
    timeout)  sc="${Y}to${R} " ;;
    fail)     sc="${RED}!!${R} " ;;
    *)        sc="${DIM}? ${R} " ;;
  esac

  # Starttime: convert UTC ISO → local time
  ts_epoch=$(date -d "$ts" +%s 2>/dev/null || echo 0)
  if [ "$ts_epoch" -gt 0 ]; then
    ts_short=$(date -d "@$ts_epoch" +"%m-%d %H:%M")
  else
    ts_short="$ts"
  fi

  [[ "$dur" == "—" || -z "$dur" ]] && dur="--"

  # Card name as topic
  topic=$(echo "$card" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//; s/\.md$//')
  [ "$topic" = "$agent" ] && topic=""

  printf "  %-14s  %-8s  %-12s  " "$ts_short" "$dur" "$agent"
  printf "%-6b  " "$sc"
  printf "%s\n" "$topic"
done <<< "$MERGED"

echo ""
