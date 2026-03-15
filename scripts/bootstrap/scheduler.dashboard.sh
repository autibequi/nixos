#!/usr/bin/env bash
# scheduler.dashboard.sh — Tabela de tasks recorrentes do CLAUDINHO scheduler

# ── Path resolution (host vs container) ──────────────────────────────────────
if [[ "${IS_CONTAINER:-0}" -eq 1 ]]; then
  _SCHED_VAULT="$WS/obsidian"
  _SCHED_EPH="$WS/host/.ephemeral"
else
  _SCHED_VAULT="${HOME}/.ovault/Work"
  _SCHED_EPH="${HOME}/nixos/.ephemeral"
fi

_STATE_FILE="$_SCHED_EPH/scheduler/state.json"
_SCHED_LOG="$_SCHED_EPH/logs/scheduler.log"
_TASKS_DIR="$_SCHED_VAULT/_agent/tasks/recurring"

# ── Helpers ───────────────────────────────────────────────────────────────────
_sched_fmt_ago() {
  local s="$1"
  if   [[ "$s" -lt 60 ]];   then echo "${s}s atrás"
  elif [[ "$s" -lt 3600 ]]; then echo "$(( s/60 ))m atrás"
  else                            echo "$(( s/3600 ))h$(( (s%3600)/60 ))m atrás"
  fi
}

_sched_fmt_in() {
  local s="$1"
  if   [[ "$s" -le 0 ]];    then echo "vencida"
  elif [[ "$s" -lt 60 ]];   then echo "em ${s}s"
  elif [[ "$s" -lt 3600 ]]; then echo "em $(( s/60 ))m"
  else                           echo "em $(( s/3600 ))h$(( (s%3600)/60 ))m"
  fi
}

_parse_fm() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return
  local in_fm=0
  while IFS= read -r line; do
    [[ "$line" == "---" ]] && { (( in_fm )) && break || in_fm=1; continue; }
    (( in_fm )) || continue
    case "$line" in "${key}:"*) echo "${line#*: }" | tr -d '[:space:]'; return ;; esac
  done < "$file"
}

# ── Read state.json via python3 ───────────────────────────────────────────────
_read_state() {
  [[ -f "$_STATE_FILE" ]] || echo "{}"
  python3 -c "
import json, sys
try:
    print(open('$_STATE_FILE').read())
except:
    print('{}')
" 2>/dev/null
}

# ── Last tick from state.json ─────────────────────────────────────────────────
_last_tick=$(python3 -c "
import json
try:
    s = json.load(open('$_STATE_FILE'))
    print(s.get('last_tick',''))
except:
    print('')
" 2>/dev/null)

# ── Scheduler header ──────────────────────────────────────────────────────────
ON=$'\033[1;32m'; OFF=$'\033[1;31m'

if [[ -n "$_last_tick" ]]; then
  _tick_epoch=$(date -d "$_last_tick" +%s 2>/dev/null || echo 0)
  _tick_age=$(( now - _tick_epoch ))
  if   [[ $_tick_age -le 120 ]];  then _tick_color="$ON";       _tick_lbl="● running"
  elif [[ $_tick_age -le 900 ]];  then _tick_color="$ON";       _tick_lbl="● ok"
  elif [[ $_tick_age -le 1800 ]]; then _tick_color="$P_AMBER";  _tick_lbl="● lento"
  else                                 _tick_color="$OFF";      _tick_lbl="● stale"
  fi
  _tick_str="${_tick_color}${_tick_lbl}${R}  ${P_DIM}última: $(_sched_fmt_ago $_tick_age)  (${_last_tick:11:5} UTC)${R}"
elif [[ -f "$_SCHED_LOG" ]]; then
  _log_age=$(( now - $(stat -c %Y "$_SCHED_LOG" 2>/dev/null || echo 0) ))
  _tick_str="${OFF}● sem histórico${R}  ${P_DIM}log: $(_sched_fmt_ago $_log_age)${R}"
else
  _tick_str="${OFF}● offline${R}  ${P_DIM}nenhum log encontrado${R}"
fi

echo -e "${P_GREEN}Bochechas  ${R}${_tick_str}"

# ── Task table ────────────────────────────────────────────────────────────────
if [[ ! -d "$_TASKS_DIR" ]]; then
  echo -e "  ${P_DIM}nenhuma task em $_TASKS_DIR${R}"
  echo
  return 0
fi

# Header da tabela
printf "  ${P_DIM}%-22s  %-5s  %-7s  %-14s  %-12s${R}\n" \
  "task" "int" "modelo" "última exec" "próxima"
printf "  ${P_DIM}%-22s  %-5s  %-7s  %-14s  %-12s${R}\n" \
  "──────────────────────" "─────" "───────" "──────────────" "────────────"

for _task_dir in "$_TASKS_DIR"/*/; do
  [[ -d "$_task_dir" ]] || continue
  _task=$(basename "$_task_dir")
  _claude_md="$_task_dir/CLAUDE.md"

  # Lê config da task
  _interval=$(_parse_fm "$_claude_md" "interval")
  _clock=$(_parse_fm "$_claude_md" "clock")
  _model=$(_parse_fm "$_claude_md" "model")

  # Normaliza interval
  if [[ -z "$_interval" ]]; then
    case "${_clock:-every60}" in
      every10)  _interval=10  ;;
      every60)  _interval=60  ;;
      every240) _interval=240 ;;
      *)        _interval=60  ;;
    esac
  fi
  _model="${_model:-haiku}"

  # Lê last_run do state.json
  _last_run=$(python3 -c "
import json
try:
    s = json.load(open('$_STATE_FILE'))
    v = s.get('tasks',{}).get('$_task',{}).get('last_run',0)
    print(int(v) if v else 0)
except:
    print(0)
" 2>/dev/null || echo 0)

  _int_s=$(( _interval * 60 ))
  _due_in=$(( _last_run + _int_s - now ))

  # Formata colunas
  if [[ "$_last_run" -eq 0 ]]; then
    _last_str="${P_DIM}nunca${R}"
    _next_str="${P_AMBER}vencida${R}"
  else
    _age=$(( now - _last_run ))
    _last_str="${P_DIM}$(_sched_fmt_ago $_age)${R}"
    if [[ $_due_in -le 0 ]]; then
      _next_str="${P_AMBER}vencida${R}"
    elif [[ $_due_in -le 120 ]]; then
      _next_str="${P_AMBER}$(_sched_fmt_in $_due_in)${R}"
    else
      _next_str="${P_GREEN}$(_sched_fmt_in $_due_in)${R}"
    fi
  fi

  # Prioridade / cor do nome
  case "$_interval" in
    10)  _name_color="$P_CYAN"   ;;
    60)  _name_color="$GREEN"    ;;
    *)   _name_color="$P_DIM"    ;;
  esac

  # Modelo cor
  case "$_model" in
    haiku)  _model_color="$P_DIM"    ;;
    sonnet) _model_color="$P_AMBER"  ;;
    opus)   _model_color="$P_MAGENTA";;
    *)      _model_color="$P_DIM"    ;;
  esac

  printf "  ${_name_color}%-22s${R}  ${P_DIM}%3dm${R}  ${_model_color}%-7s${R}  %-14b  %b\n" \
    "$_task" "$_interval" "$_model" "$_last_str" "$_next_str"
done

echo
