#!/usr/bin/env bash
# scheduler.dashboard.sh — Tabela de tasks recorrentes do CLAUDINHO scheduler

# ── Path resolution (host vs container) ──────────────────────────────────────
if [[ "${IS_CONTAINER:-0}" -eq 1 ]]; then
  _SCHED_VAULT="$WS/obsidian"
  _SCHED_EPH="$WS/host/.ephemeral"
else
  _SCHED_VAULT="${HOME}/.ovault/Zion"
  _SCHED_EPH="${HOME}/nixos/.ephemeral"
fi

_STATE_FILE="$_SCHED_EPH/scheduler/state.json"
_SCHED_LOG="$_SCHED_EPH/logs/scheduler.log"
_TASKS_DIR="$_SCHED_VAULT/tasks/_scheduled"

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

# ── Read all state in one python3 call ───────────────────────────────────────
# Format: first line = last_tick, remaining lines = task_name:last_run_epoch
_state_data=$(python3 -c "
import json
try:
    s = json.load(open('$_STATE_FILE'))
    print(s.get('last_tick', ''))
    for k, v in s.get('tasks', {}).items():
        lr = v.get('last_run', 0) if isinstance(v, dict) else 0
        print(k + ':' + str(int(lr) if lr else 0))
except:
    print('')
" 2>/dev/null)

_last_tick=$(printf '%s\n' "$_state_data" | head -1)

declare -A _task_last_runs
while IFS=':' read -r _k _v; do
  [[ -n "$_k" && -n "$_v" ]] && _task_last_runs["$_k"]="$_v"
done < <(printf '%s\n' "$_state_data" | tail -n +2)

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

echo -e "${P_GREEN}Puppies  ${R}${_tick_str}"

# ── Padding helper (ignora ANSI escapes no cálculo de largura) ───────────────
_ansi_pad() {
  local str="$1" width="$2"
  local vis
  vis=$(printf '%b' "$str" | sed $'s/\033\\[[0-9;]*m//g')
  local pad=$(( width - ${#vis} ))
  [[ $pad -lt 0 ]] && pad=0
  printf '%b%*s' "$str" "$pad" ""
}

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
  # TASK.md preferred, fallback to CLAUDE.md
  if [[ -f "$_task_dir/TASK.md" ]]; then _claude_md="$_task_dir/TASK.md"
  else _claude_md="$_task_dir/CLAUDE.md"; fi

  # Lê config da task
  _interval=$(_parse_fm "$_claude_md" "interval")
  _clock=$(_parse_fm "$_claude_md" "clock")
  _model=$(_parse_fm "$_claude_md" "model")

  # Normaliza interval (suporta padrões novos e legados)
  if [[ -z "$_interval" ]]; then
    case "${_clock:-every60}" in
      every5m)             _interval=5   ;;
      every10|every10m)    _interval=10  ;;
      every15m)            _interval=15  ;;
      every30m)            _interval=30  ;;
      every60|every60m|every1h) _interval=60 ;;
      every2h)             _interval=120 ;;
      every4h|every240)    _interval=240 ;;
      every6h)             _interval=360 ;;
      every12h)            _interval=720 ;;
      every24h|daily|daily@*) _interval=1440 ;;
      *)                   _interval=60  ;;
    esac
  fi
  _model="${_model:-haiku}"

  # Lê last_run do array pré-carregado
  _last_run="${_task_last_runs[$_task]:-0}"

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

  printf "  ${_name_color}%-22s${R}  ${P_DIM}%-5s${R}  ${_model_color}%-7s${R}  %s  %s\n" \
    "$_task" "${_interval}m" "$_model" \
    "$(_ansi_pad "$_last_str" 14)" \
    "$(_ansi_pad "$_next_str" 12)"
done

echo

# ── Task column summary ────────────────────────────────────────────────────────
_tasks_root="$_SCHED_VAULT/tasks"
if [[ -d "$_tasks_root" ]]; then
  _summary=""
  for _col in inbox backlog doing done blocked cancelled _waiting; do
    _cnt=$(ls "$_tasks_root/$_col/" 2>/dev/null | wc -l)
    [[ "$_cnt" -gt 0 ]] && _summary="${_summary}${_col}:${_cnt}  "
  done
  [[ -n "$_summary" ]] && echo -e "  ${P_DIM}kanban ${R}${_summary}"
fi
