#!/usr/bin/env bash
# task-schedule.sh — Mostra tabela de tasks agendadas por slot de execução
# Lê scheduled.md (recorrentes) e task files (frontmatter) para montar timeline
set -euo pipefail

WS="${WORKSPACE:-/workspace}"
TASKS="$WS/vault/_agent/tasks"
SCHEDULED="$WS/vault/_agent/scheduled.md"
EPHEMERAL="$WS/.ephemeral"

# Cores
R='\033[0m' B='\033[1m' DIM='\033[2m'
CYAN='\033[36m' GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m'
ORANGE='\033[38;5;208m' BLUE='\033[38;5;33m' MAGENTA='\033[35m' WHITE='\033[97m'

# ── Frontmatter parser ──────────────────────────────────────────
parse_fm() {
  local file="$1" key="$2"
  [ -f "$file" ] || return
  local in_fm=0
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      [ "$in_fm" = "1" ] && break
      in_fm=1; continue
    fi
    if [ "$in_fm" = "1" ]; then
      case "$line" in
        "${key}:"*) echo "${line#*: }" | tr -d '[:space:]'; return ;;
      esac
    fi
  done < "$file"
}

# ── Coletar info dos workers ────────────────────────────────────
now=$(date +%s)
fmt_age() {
  local h=$(( $1 / 3600 )) m=$(( ($1 % 3600) / 60 ))
  [[ $h -gt 0 ]] && echo "${h}h${m}m" || echo "${m}m"
}

worker_status() {
  local clock="$1"
  local logfile="$EPHEMERAL/logs/worker-${clock}.log"
  if [[ -f "$logfile" ]]; then
    local mod age
    mod=$(stat -c %Y "$logfile" 2>/dev/null || echo 0)
    age=$(( now - mod ))
    if [[ $age -le 120 ]]; then
      echo "running"
    else
      echo "$(fmt_age $age) ago"
    fi
  else
    echo "--"
  fi
}

# ── Coletar tasks recorrentes do scheduled.md ───────────────────
declare -A task_clock task_model task_timeout task_schedule task_mcp task_max_turns task_desc

if [[ -f "$SCHEDULED" ]]; then
  in_rec=0
  while IFS= read -r line; do
    [[ "$line" == "## Recorrentes" ]] && { in_rec=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_rec" == "1" ]] && break
    if [[ "$in_rec" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
      # Parse: - [ ] **nome** — descrição `#every60` `#haiku` ...
      after="${line#*\*\*}"; name="${after%%\*\**}"

      # Extrair descrição
      desc=""
      if [[ "$line" == *" — "* ]]; then
        raw="${line##* — }"
        # Remove tags inline
        desc=$(echo "$raw" | sed 's/`#[^`]*`//g; s/`[^`]*`//g; s/  */ /g; s/^ //; s/ $//')
      fi
      task_desc[$name]="$desc"

      # Tentar ler frontmatter do CLAUDE.md da task
      task_file=""
      for candidate in "$TASKS/recurring/$name/CLAUDE.md" "$TASKS/recurring/$name/$name/CLAUDE.md"; do
        [[ -f "$candidate" ]] && { task_file="$candidate"; break; }
      done

      if [[ -n "$task_file" ]]; then
        task_clock[$name]=$(parse_fm "$task_file" "clock")
        task_model[$name]=$(parse_fm "$task_file" "model")
        task_timeout[$name]=$(parse_fm "$task_file" "timeout")
        task_schedule[$name]=$(parse_fm "$task_file" "schedule")
        task_mcp[$name]=$(parse_fm "$task_file" "mcp")
        task_max_turns[$name]=$(parse_fm "$task_file" "max_turns")
      fi

      # Fallback: parse tags inline do scheduled.md
      if [[ -z "${task_clock[$name]:-}" ]]; then
        if [[ "$line" == *'#every10'* ]]; then task_clock[$name]="every10"
        elif [[ "$line" == *'#every240'* ]]; then task_clock[$name]="every240"
        else task_clock[$name]="every60"; fi
      fi
      if [[ -z "${task_model[$name]:-}" ]]; then
        if [[ "$line" == *'#haiku'* ]]; then task_model[$name]="haiku"
        elif [[ "$line" == *'#sonnet'* ]]; then task_model[$name]="sonnet"
        elif [[ "$line" == *'#opus'* ]]; then task_model[$name]="opus"
        else task_model[$name]="haiku"; fi
      fi
      [[ -z "${task_timeout[$name]:-}" ]] && task_timeout[$name]="300"
      [[ -z "${task_schedule[$name]:-}" ]] && task_schedule[$name]="always"
      [[ -z "${task_mcp[$name]:-}" ]] && task_mcp[$name]="false"
      [[ -z "${task_max_turns[$name]:-}" ]] && task_max_turns[$name]="12"
    fi
  done < "$SCHEDULED"
fi

# ── Tasks em running (atualmente executando) ────────────────────
declare -A running_tasks
for dir in "$TASKS/running"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  worker=""
  if [[ -f "$dir/.lock" ]]; then
    worker=$(grep '^worker=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "")
  fi
  running_tasks[$name]="$worker"
done

# ── Tasks pending (backlog one-shots) ───────────────────────────
declare -A pending_clock pending_model pending_desc
for dir in "$TASKS/pending"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  task_file="$dir/CLAUDE.md"
  [[ -f "$task_file" ]] || continue
  pending_clock[$name]=$(parse_fm "$task_file" "clock")
  [[ -z "${pending_clock[$name]:-}" ]] && pending_clock[$name]="every60"
  pending_model[$name]=$(parse_fm "$task_file" "model")
  [[ -z "${pending_model[$name]:-}" ]] && pending_model[$name]="haiku"
  # Descrição: primeira linha # do CLAUDE.md
  pending_desc[$name]=$(grep '^# ' "$task_file" | head -1 | sed 's/^# //')
done

# ── Renderizar ──────────────────────────────────────────────────
echo
echo -e "${B}${WHITE}╔══════════════════════════════════════════════════════════════════════╗${R}"
echo -e "${B}${WHITE}║${R}  ${B}Task Schedule${R} — $(date '+%Y-%m-%d %H:%M')                              ${B}${WHITE}║${R}"
echo -e "${B}${WHITE}╚══════════════════════════════════════════════════════════════════════╝${R}"
echo

# Worker status
e10_st=$(worker_status "every10")
e60_st=$(worker_status "every60")
e240_st=$(worker_status "every240")
echo -e "${B}Workers:${R}  ${GREEN}●${R} every10 ${DIM}(${e10_st})${R}   ${GREEN}●${R} every60 ${DIM}(${e60_st})${R}   ${GREEN}●${R} every240 ${DIM}(${e240_st})${R}"
echo

# Model color helper
model_color() {
  case "$1" in
    haiku)  echo -ne "${GREEN}$1${R}" ;;
    sonnet) echo -ne "${YELLOW}$1${R}" ;;
    opus)   echo -ne "${ORANGE}$1${R}" ;;
    *)      echo -ne "${DIM}$1${R}" ;;
  esac
}

# ── Tabela por clock ────────────────────────────────────────────
for clock in every10 every60 every240; do
  case "$clock" in
    every10)  freq="10 min"; color="$GREEN" ;;
    every60)  freq="1 hora"; color="$YELLOW" ;;
    every240) freq="4 horas"; color="$ORANGE" ;;
  esac

  echo -e "${B}${color}▸ ${clock}${R} ${DIM}(a cada ${freq})${R}"
  echo -e "  ${DIM}┌──────────────────────────┬────────┬────────┬──────┬─────────┬────────────────────────────────┐${R}"
  printf "  ${DIM}│${R} ${B}%-24s${R} ${DIM}│${R} ${B}%-6s${R} ${DIM}│${R} ${B}%-6s${R} ${DIM}│${R} ${B}%-4s${R} ${DIM}│${R} ${B}%-7s${R} ${DIM}│${R} ${B}%-30s${R} ${DIM}│${R}\n" \
    "Task" "Modelo" "Timer" "MCP" "Status" "Descrição"
  echo -e "  ${DIM}├──────────────────────────┼────────┼────────┼──────┼─────────┼────────────────────────────────┤${R}"

  has_items=0

  # Recorrentes neste clock
  for name in $(echo "${!task_clock[@]}" | tr ' ' '\n' | sort); do
    [[ "${task_clock[$name]}" == "$clock" ]] || continue
    has_items=1

    model="${task_model[$name]:-haiku}"
    timeout="${task_timeout[$name]:-300}"
    mcp="${task_mcp[$name]:-false}"
    sched="${task_schedule[$name]:-always}"
    desc="${task_desc[$name]:-}"

    # Status
    status=""
    if [[ -n "${running_tasks[$name]:-}" ]]; then
      status="${CYAN}running${R}"
    elif [[ "$sched" == "night" ]]; then
      hour=$(date +%H)
      if (( hour >= 22 || hour < 6 )); then
        status="${GREEN}ready${R}"
      else
        status="${DIM}night${R}"
      fi
    else
      status="${GREEN}ready${R}"
    fi

    # MCP indicator
    mcp_str=""
    [[ "$mcp" == "true" ]] && mcp_str="${CYAN}yes${R}" || mcp_str="${DIM}no${R}"

    # Model colored
    model_str=$(model_color "$model")

    # Timeout formatted
    timeout_str="${timeout}s"

    # Truncar desc
    [[ ${#desc} -gt 30 ]] && desc="${desc:0:27}..."

    printf "  ${DIM}│${R} ♻ %-23s ${DIM}│${R} " "$name"
    echo -ne "$model_str"
    pad=$(( 6 - ${#model} ))
    printf "%${pad}s" ""
    printf " ${DIM}│${R} %-6s ${DIM}│${R} " "$timeout_str"
    echo -ne "$mcp_str"
    [[ "$mcp" == "true" ]] && mcp_len=3 || mcp_len=2
    pad=$(( 4 - mcp_len ))
    printf "%${pad}s" ""
    printf " ${DIM}│${R} "
    echo -ne "$status"
    # Calculate status visible length
    if [[ -n "${running_tasks[$name]:-}" ]]; then
      slen=7
    elif [[ "$sched" == "night" ]]; then
      hour=$(date +%H)
      if (( hour >= 22 || hour < 6 )); then slen=5; else slen=5; fi
    else
      slen=5
    fi
    pad=$(( 7 - slen ))
    printf "%${pad}s" ""
    printf " ${DIM}│${R} ${DIM}%-30s${R} ${DIM}│${R}\n" "$desc"
  done

  # Pending neste clock
  for name in $(echo "${!pending_clock[@]}" | tr ' ' '\n' | sort); do
    [[ "${pending_clock[$name]}" == "$clock" ]] || continue
    has_items=1

    model="${pending_model[$name]:-haiku}"
    desc="${pending_desc[$name]:-}"
    [[ ${#desc} -gt 30 ]] && desc="${desc:0:27}..."

    status=""
    if [[ -n "${running_tasks[$name]:-}" ]]; then
      status="${CYAN}running${R}"
      slen=7
    else
      status="${YELLOW}pending${R}"
      slen=7
    fi

    model_str=$(model_color "$model")

    printf "  ${DIM}│${R} ◇ %-23s ${DIM}│${R} " "$name"
    echo -ne "$model_str"
    pad=$(( 6 - ${#model} ))
    printf "%${pad}s" ""
    printf " ${DIM}│${R} %-6s ${DIM}│${R} ${DIM}%-4s${R} ${DIM}│${R} " "--" "--"
    echo -ne "$status"
    pad=$(( 7 - slen ))
    printf "%${pad}s" ""
    printf " ${DIM}│${R} ${DIM}%-30s${R} ${DIM}│${R}\n" "$desc"
  done

  if [[ "$has_items" == "0" ]]; then
    printf "  ${DIM}│${R} ${DIM}%-24s${R} ${DIM}│${R} ${DIM}%-6s${R} ${DIM}│${R} ${DIM}%-6s${R} ${DIM}│${R} ${DIM}%-4s${R} ${DIM}│${R} ${DIM}%-7s${R} ${DIM}│${R} ${DIM}%-30s${R} ${DIM}│${R}\n" \
      "(nenhuma)" "--" "--" "--" "--" ""
  fi

  echo -e "  ${DIM}└──────────────────────────┴────────┴────────┴──────┴─────────┴────────────────────────────────┘${R}"
  echo
done

# ── Timeline visual ─────────────────────────────────────────────
echo -e "${B}Timeline (próximas horas):${R}"
echo

hour_now=$(date +%H)
min_now=$(date +%M)

for offset in 0 1 2 3; do
  h=$(( (hour_now + offset) % 24 ))
  hh=$(printf "%02d" $h)

  # Quais tasks rodam neste slot?
  slot_tasks=()

  # every10 roda todo slot
  for name in $(echo "${!task_clock[@]}" | tr ' ' '\n' | sort); do
    [[ "${task_clock[$name]}" == "every10" ]] || continue
    sched="${task_schedule[$name]:-always}"
    if [[ "$sched" == "night" ]] && (( h >= 6 && h < 22 )); then continue; fi
    slot_tasks+=("${GREEN}${name}${R}")
  done

  # every60 roda todo slot
  for name in $(echo "${!task_clock[@]}" | tr ' ' '\n' | sort); do
    [[ "${task_clock[$name]}" == "every60" ]] || continue
    sched="${task_schedule[$name]:-always}"
    if [[ "$sched" == "night" ]] && (( h >= 6 && h < 22 )); then continue; fi
    slot_tasks+=("${YELLOW}${name}${R}")
  done

  # every240 roda a cada 4h (0, 4, 8, 12, 16, 20)
  if (( h % 4 == 0 )); then
    for name in $(echo "${!task_clock[@]}" | tr ' ' '\n' | sort); do
      [[ "${task_clock[$name]}" == "every240" ]] || continue
      sched="${task_schedule[$name]:-always}"
      if [[ "$sched" == "night" ]] && (( h >= 6 && h < 22 )); then continue; fi
      slot_tasks+=("${ORANGE}${name}${R}")
    done
  fi

  # Pending one-shots (show in next slot only)
  if [[ $offset -eq 0 ]]; then
    for name in $(echo "${!pending_clock[@]}" | tr ' ' '\n' | sort); do
      slot_tasks+=("${MAGENTA}${name}${R}")
    done
  fi

  # Marker for current hour
  marker="  "
  [[ $offset -eq 0 ]] && marker="${CYAN}▸ ${R}"

  echo -ne "${marker}${B}${hh}:00${R}  "
  if [[ ${#slot_tasks[@]} -gt 0 ]]; then
    first=1
    for t in "${slot_tasks[@]}"; do
      [[ $first -eq 0 ]] && echo -ne "${DIM}, ${R}"
      echo -ne "$t"
      first=0
    done
    echo
  else
    echo -e "${DIM}(idle)${R}"
  fi
done

echo
echo -e "${DIM}Legenda: ♻ recorrente  ◇ one-shot  ${GREEN}●every10${R}  ${YELLOW}●every60${R}  ${ORANGE}●every240${R}  ${MAGENTA}●pending${R}${R}"
echo
