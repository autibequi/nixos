#!/usr/bin/env bash
# header.dashboard.sh — Weather, banner, workers, git status, flags, inbox

# ── Weather (cache + background refresh) ──────────────────────────────────────
WEATHER_LOCATION="São Paulo"
WEATHER_CAT="cloudy"; WEATHER_TEMP="--"; WEATHER_FEELS=""; WEATHER_DESC="indisponível"
WEATHER_HUMIDITY=""; WEATHER_WIND=""; WEATHER_TMAX=""; WEATHER_TMIN=""
WEATHER_SUNRISE=""; WEATHER_SUNSET=""; WEATHER_HOUR_COUNT=0; WEATHER_WEEK_COUNT=0
WEATHER_ART=("      .---.      " "   .-(     ).    " "  (___________)  " "                 " "                 " "                 " "                 " "                 ")
mkdir -p "$WS/.ephemeral" 2>/dev/null || true
WEATHER_BOOTSTRAP_CACHE="$WS/.ephemeral/.weather-bootstrap.sh"
[[ -f "$WEATHER_BOOTSTRAP_CACHE" ]] && source "$WEATHER_BOOTSTRAP_CACHE" 2>/dev/null || true
weather_cache_age=999999
[[ -f "$WEATHER_BOOTSTRAP_CACHE" ]] && weather_cache_age=$(( now - $(stat -c %Y "$WEATHER_BOOTSTRAP_CACHE" 2>/dev/null || echo 0) ))
if [[ $weather_cache_age -gt 1500 ]]; then
  ( WS="$WS" WEATHER_LOCATION="São Paulo" source "$WS/stow/.claude/scripts/weather-art.sh" 2>/dev/null
    declare -p WEATHER_CAT WEATHER_TEMP WEATHER_FEELS WEATHER_DESC WEATHER_HUMIDITY WEATHER_WIND WEATHER_TMAX WEATHER_TMIN WEATHER_SUNRISE WEATHER_SUNSET WEATHER_HOUR_COUNT WEATHER_WEEK_COUNT WEATHER_ART 2>/dev/null
    for i in 0 1 2 3 4 5 6 7; do declare -p WEATHER_HOUR_$i 2>/dev/null; done
    for i in 0 1 2 3 4 5; do declare -p WEATHER_WEEK_$i 2>/dev/null; done
  ) > "$WEATHER_BOOTSTRAP_CACHE" 2>/dev/null &
  disown 2>/dev/null || true
fi

# ── Auto-update Claude Code (cache 24h) ──────────────────────────────────────
CLAUDE_UPDATE_CACHE="$WS/.ephemeral/.claude-code-update"
if [[ -f "$CLAUDE_UPDATE_CACHE" ]]; then
  update_age=$(( now - $(stat -c %Y "$CLAUDE_UPDATE_CACHE" 2>/dev/null || echo 0) ))
else
  update_age=999999
fi
if [[ $update_age -gt 86400 ]]; then
  ( nix profile upgrade '.*claude-code.*' 2>/dev/null && \
    touch "$CLAUDE_UPDATE_CACHE" 2>/dev/null || true ) &
fi

# ── Quotes ────────────────────────────────────────────────────────────────────
DIA=$(date +"%d/%m/%Y")
HORA=$(date +"%H:%M")

PORQUEMOS=(
  "Por que compilar se um dia tudo vira pó?"
  "Por que debugar se a vida já é um bug?"
  "Por que deploy na sexta se Deus descansou?"
  "Por que tipar se o universo é dinâmico?"
  "Por que nomear variável se nada é permanente?"
  "Por que refatorar se o sol vai engolir a Terra?"
  "Por que testar se não testamos a existência?"
  "Por que usar git se o tempo é uma ilusão?"
  "Por que cachear se toda memória é efêmera?"
  "Por que documentar se ninguém lê?"
  "Por que otimizar se o heat death é inevitável?"
  "Por que branch se todo caminho leva ao merge?"
  "Por que lint se a entropia sempre vence?"
  "Por que microserviço se somos monolitos?"
  "Por que container se nada contém o vazio?"
  "Por que await se o tempo não espera ninguém?"
  "Por que CI/CD se o destino é o mesmo pra todos?"
  "Por que dry-run se a vida não tem dry-run?"
  "Por que null check se o nada é a única certeza?"
  "Por que fechar conexão se tudo se desconecta?"
)
PORQUEMO="${PORQUEMOS[$((RANDOM % ${#PORQUEMOS[@]}))]}"

# ── Weather desc color ────────────────────────────────────────────────────────
weather_desc_color() {
  case "${WEATHER_CAT:-cloudy}" in
    sunny)         echo -ne "${P_AMBER}" ;;
    partly_cloudy) echo -ne "${P_CYAN}" ;;
    rainy|stormy)  echo -ne "${P_CYAN}" ;;
    snowy)         echo -ne "${P_CYAN}" ;;
    foggy)         echo -ne "${P_DIM}" ;;
    *)             echo -ne "${P_CYAN}" ;;
  esac
}

# ── Banner ────────────────────────────────────────────────────────────────────
build_banner() {
  local compact=0
  [[ "$BOOTSTRAP_BANNER" == "compact" ]] && compact=1

  # Data/hora + tempo
  local weather_now="${P_CYAN}${DIA}  ${HORA}${R}  ${P_DIM}│${R}  "
  weather_now+="${P_AMBER}${WEATHER_TEMP:-?}°C${R}"
  if [[ $compact -eq 0 ]]; then
    [[ -n "${WEATHER_FEELS:-}" && "${WEATHER_FEELS:-}" != "${WEATHER_TEMP:-}" ]] && \
      weather_now+=" ${P_DIM}(${WEATHER_FEELS}° sens.)${R}"
  fi
  weather_now+="  $(weather_desc_color)${WEATHER_DESC:-?}${R}"
  [[ -n "${WEATHER_HUMIDITY:-}" ]] && weather_now+="  ${P_CYAN}${WEATHER_HUMIDITY}% 💧${R}"
  [[ $compact -eq 0 && -n "${WEATHER_WIND:-}" ]] && weather_now+="  ${P_DIM}🌬 ${WEATHER_WIND} km/h${R}"

  local today_range=""
  [[ -n "${WEATHER_TMIN:-}" ]] && today_range="${P_CYAN}${WEATHER_TMIN}°–${WEATHER_TMAX}°${R}"
  [[ $compact -eq 0 && -n "${WEATHER_SUNRISE:-}" ]] && today_range+="  ${P_AMBER}☀ ${WEATHER_SUNRISE} – ${WEATHER_SUNSET}${R}"

  local today_hours=""
  if [[ $compact -eq 0 ]]; then
    for (( h=0; h<${WEATHER_HOUR_COUNT:-0}; h++ )); do
      local vname="WEATHER_HOUR_${h}"
      [[ -n "$today_hours" ]] && today_hours+="  "
      today_hours+="${P_CYAN}${!vname:-}${R}"
    done
  fi

  local info_lines=()
  if [[ $compact -eq 1 ]]; then
    info_lines=(
      "$weather_now"
      ""
      "${P_DIM}Hoje:${R} ${today_range}"
    )
  else
    local week_lines=()
    for (( w=0; w<${WEATHER_WEEK_COUNT:-0}; w++ )); do
      local vname="WEATHER_WEEK_${w}"
      local line="${!vname:-}"
      [[ -z "${line// }" ]] && continue
      week_lines+=("  ${P_GREEN}${line%% *}${R} ${P_CYAN}${line#* }${R}")
    done
    info_lines=(
      "$weather_now"
      ""
      "${P_DIM}Hoje:${R} ${today_range}"
      "${P_DIM}Horário:${R} ${today_hours}"
    )
    [[ ${#week_lines[@]} -gt 0 ]] && {
      info_lines+=("${P_DIM}Próximos dias:${R}")
      for wl in "${week_lines[@]}"; do info_lines+=("  $wl"); done
    }
  fi

  for (( i=0; i<${#info_lines[@]}; i++ )); do
    echo -e "${info_lines[$i]:-}"
  done
}

build_banner
echo

# ── Scheduler (unified single timer) ──────────────────────────────────────────
ON=$'\033[1;32m'  # bright green
OFF=$'\033[1;31m' # bright red
scheduler_log="$WS/.ephemeral/logs/scheduler.log"
scheduler_state="$WS/.ephemeral/scheduler/state.json"

if [[ -f "$scheduler_log" ]]; then
  sched_mod=$(stat -c %Y "$scheduler_log" 2>/dev/null || echo 0)
  sched_age=$(( now - sched_mod ))
  if [[ $sched_age -le 120 ]]; then
    sched_status="${ON}● scheduler${R} ${P_DIM}running${R}"
  elif [[ $sched_age -le 900 ]]; then
    sched_status="${ON}● scheduler${R} ${P_DIM}$(fmt_age $sched_age)${R}"
  elif [[ $sched_age -le 1800 ]]; then
    sched_status="${P_AMBER}● scheduler${R} ${P_DIM}$(fmt_age $sched_age)${R}"
  else
    sched_status="${OFF}● scheduler${R} ${P_DIM}$(fmt_age $sched_age) stale${R}"
  fi
else
  sched_status="${OFF}● scheduler${R} ${P_DIM}offline${R}"
fi

# Count tasks from state.json
task_count=0
if [[ -f "$scheduler_state" ]]; then
  task_count=$(python3 -c "import json; print(len(json.load(open('$scheduler_state')).get('tasks',{})))" 2>/dev/null || echo 0)
fi
echo -e "${P_GREEN}Bochechas:${R} ${sched_status}  ${P_DIM}(${task_count} tasks tracked)${R}"
echo

# ── Agents (dynamic from stow/.claude/agents/) ───────────────────────────────
agents_list=()
if [[ -d ~/.claude/agents ]]; then
  for agent_dir in ~/.claude/agents/*/; do
    [[ -d "$agent_dir" ]] || continue
    agents_list+=("$(basename "$agent_dir")")
  done
fi

# ── Git + Mode flags ─────────────────────────────────────────────────────────
ws_branch=$(git -C "$WS" branch --show-current 2>/dev/null || echo "?")
ws_dirty=$(git -C "$WS" status --porcelain 2>/dev/null | head -1)
ws_ahead=$(git -C "$WS" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
ws_behind=$(git -C "$WS" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
git_str="${P_CYAN}[${ws_branch}]${R}"
[[ -n "$ws_dirty" ]] && git_str+=" ${P_AMBER}dirty${R}" || git_str+=" ${P_GREEN}clean${R}"
[[ "$ws_ahead" -gt 0 ]] && git_str+=" ${P_GREEN}↑${ws_ahead}${R}"
[[ "$ws_behind" -gt 0 ]] && git_str+=" ${P_RED}↓${ws_behind}${R}"

MODE_FILE="$WS/projetos/CLAUDE.md"
if [[ -f "$MODE_FILE" ]] && grep -q 'FÉRIAS \[OFF\]' "$MODE_FILE" 2>/dev/null; then
  ferias_str="${OFF}OFF${R}"
else
  ferias_str="${ON}ON${R}"
fi
PERSONALITY_FLAG="$WS/.ephemeral/personality-off"
[[ -f "$PERSONALITY_FLAG" ]] && personality_str="${OFF}OFF${R}" || personality_str="${ON}ON${R}"
AUTOCOMMIT_FLAG="$WS/.ephemeral/auto-commit"
[[ -f "$AUTOCOMMIT_FLAG" ]] && autocommit_str="${ON}ON${R}" || autocommit_str="${OFF}OFF${R}"
[[ -f "$AUTOJARVIS_FLAG" ]] && autojarvis_str="${ON}ON${R}" || autojarvis_str="${OFF}OFF${R}"

[[ "${IS_CONTAINER:-0}" -eq 1 ]] && env_str="${P_CYAN}CONTAINER${R}" || env_str="${P_GREEN}HOST${R}"
echo -e "${P_CYAN}Env:${R} ${env_str}  ${P_CYAN}Git:${R} ${git_str}  ${P_CYAN}Ferias:${R} ${ferias_str}  ${P_CYAN}Personality:${R} ${personality_str}  ${P_CYAN}AutoCommit:${R} ${autocommit_str}  ${P_CYAN}AutoJarvis:${R} ${autojarvis_str}"

# ── Kanban: Inbox count ───────────────────────────────────────────────────────
inbox_count=0
if [[ -f "$KANBAN" ]]; then
  section=""
  while IFS= read -r line; do
    case "$line" in
      "## Inbox") section="inbox"; continue ;;
      "## Esperando Review"|"## Em Andamento"|"## Backlog"|"## Aprovado"|"## Falhou") section=""; continue ;;
    esac
    [[ "$line" =~ ^##\  ]] && { section=""; continue; }
    [[ "$line" =~ ^-\ \[ ]] || continue
    [[ "$section" == "inbox" ]] && inbox_count=$((inbox_count + 1))
  done < "$KANBAN"
fi

[[ "$inbox_count" -gt 0 ]] && echo -e "${P_CYAN}Inbox:${R} ${P_AMBER}${inbox_count} pendente(s)${R}"
echo
