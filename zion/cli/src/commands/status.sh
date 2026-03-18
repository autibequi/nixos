# Status agregado: sessoes Zion, Docker services e Puppy workers.
zion_load_config

# ── Cores ──────────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
WHITE='\033[37m'
ORANGE='\033[38;5;214m'

icon_running="${GREEN}●${RESET}"
icon_stopped="${RED}○${RESET}"
icon_partial="${YELLOW}◐${RESET}"

# ── Helpers ────────────────────────────────────────────────────────────────────

fmt_uptime() {
  local s="$1"
  if echo "$s" | grep -qi "up"; then
    local t
    t=$(echo "$s" | sed -E 's/Up //i; s/ \(.*\)//')
    t=$(echo "$t" | sed -E 's/ minutes?/min/; s/ hours?/h/; s/ days?/d/; s/ weeks?/w/; s/ seconds?/s/')
    local healthy=""
    echo "$s" | grep -qi "healthy" && healthy=" ${GREEN}✓${RESET}"
    echo "${ORANGE}${t}${RESET}${healthy}"
  elif echo "$s" | grep -qi "exited"; then
    echo "${RED}exited${RESET}"
  else
    echo "${YELLOW}${s}${RESET}"
  fi
}

fmt_ports() {
  local raw="$1"
  [[ -z "$raw" ]] && return
  echo "$raw" \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+->[0-9]+' \
    | grep -oE ':[0-9]+->' \
    | sed 's/->//' \
    | sort -u \
    | tr '\n' '  ' \
    | sed 's/  $//'
}

# Print a container row: prefix, name, status, ports
row() {
  local pfx="$1" name="$2" status="$3" ports="$4"
  local TIME_W=9 NAME_W=16
  local st
  st=$(fmt_uptime "$status")
  local fp=""
  fp=$(fmt_ports "$ports")
  local ps=""
  [[ -n "$fp" ]] && ps="  ${DIM}${fp}${RESET}"
  echo -e "${pfx}$(printf "%-${TIME_W}b" "$st")  ${WHITE}$(printf "%-${NAME_W}s" "$name")${RESET}${ps}"
}

# ── Header ─────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${MAGENTA}  Zion Status${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}\n"

# ══════════════════════════════════════════════════════════════════════════════
# 1. SESSIONS — containers zion-* (sessoes do agente)
# ══════════════════════════════════════════════════════════════════════════════
echo -e "${BOLD}${CYAN}  Sessions${RESET}"

session_rows=$(docker ps -a --filter "name=zion-" --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
  | grep -v "zion-dk-" || true)

if [[ -z "$session_rows" ]]; then
  echo -e "  ${DIM}(nenhuma)${RESET}"
else
  while IFS=$'\t' read -r name status ports; do
    [[ -z "$name" ]] && continue
    s_icon="$icon_stopped"
    echo "$status" | grep -qi "up" && s_icon="$icon_running"
    short="${name#zion-}"
    row "  ${s_icon} " "$short" "$status" "$ports"
  done <<< "$session_rows"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 2. DOCKER SERVICES — estrategia (monolito, bo-container, front-student)
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Docker Services${RESET}"

for svc in monolito bo-container front-student; do
  project=$(zion_docker_project_name "$svc")
  compose=$(zion_docker_compose_file "$svc" 2>/dev/null || echo "")

  # Main containers
  main_rows=""
  if [[ -n "$compose" ]] && [[ -f "$compose" ]]; then
    main_rows=$(docker compose -f "$compose" -p "$project" ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)
  fi

  # Deps containers
  dep_rows=$(docker compose -p "${project}-deps" ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)

  running=0; total=0
  for block in "$main_rows" "$dep_rows"; do
    [[ -z "$block" ]] && continue
    while IFS=$'\t' read -r n s p; do
      [[ -z "$n" ]] && continue
      total=$((total + 1))
      echo "$s" | grep -qi "up" && running=$((running + 1))
    done <<< "$block"
  done

  if [[ "$total" -eq 0 ]]; then
    echo -e "  ${icon_stopped} ${BOLD}${svc}${RESET}  ${DIM}parado${RESET}"
    continue
  fi

  svc_icon="$icon_running"
  [[ "$running" -lt "$total" ]] && svc_icon="$icon_partial"
  [[ "$running" -eq 0 ]] && svc_icon="$icon_stopped"
  echo -e "  ${svc_icon} ${BOLD}${svc}${RESET}"

  # Main
  if [[ -n "$main_rows" ]]; then
    has_deps=0
    [[ -n "$dep_rows" ]] && has_deps=1
    cont="   "; [[ "$has_deps" -eq 1 ]] && cont="│  "
    while IFS=$'\t' read -r name status ports; do
      [[ -z "$name" ]] && continue
      short="${name##${project}-}"
      row "    ${cont}└─ " "$short" "$status" "$ports"
    done <<< "$main_rows"
  fi

  # Deps
  if [[ -n "$dep_rows" ]]; then
    echo -e "    ${BLUE}└─${RESET} ${DIM}deps${RESET}"
    dep_arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && dep_arr+=("$line"); done <<< "$dep_rows"
    idx=0
    for dep_row in "${dep_arr[@]}"; do
      idx=$((idx + 1))
      IFS=$'\t' read -r name status ports <<< "$dep_row"
      [[ -z "$name" ]] && continue
      short="${name##zion-dk-${svc}-}"
      tc="├─"; [[ "$idx" -eq "${#dep_arr[@]}" ]] && tc="└─"
      row "       ${tc} " "$short" "$status" "$ports"
    done
  fi
done

# ══════════════════════════════════════════════════════════════════════════════
# 3. PUPPY — worker persistente
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Puppy${RESET}"

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

puppy_rows=$(OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)

if [[ -z "$puppy_rows" ]]; then
  echo -e "  ${icon_stopped} ${BOLD}container${RESET}  ${DIM}parado${RESET}"
else
  while IFS=$'\t' read -r name status ports; do
    [[ -z "$name" ]] && continue
    p_icon="$icon_stopped"
    echo "$status" | grep -qi "up" && p_icon="$icon_running"
    short="${name##${PUPPY_PROJECT}-}"
    row "  ${p_icon} " "$short" "$status" "$ports"
  done <<< "$puppy_rows"
fi

# Tasks em doing/
vault="${zion_obsidian_path}/tasks/doing"
doing_count=0
if [ -d "$vault" ] && [ -n "$(ls -A "$vault" 2>/dev/null)" ]; then
  for d in "$vault"/*/; do
    [ -d "$d" ] || continue
    doing_count=$((doing_count + 1))
    name=$(basename "$d")
    lock_info=""
    [ -f "$d/.lock" ] && lock_info=" ${DIM}(locked: $(grep '^worker=' "$d/.lock" 2>/dev/null | cut -d= -f2))${RESET}"
    echo -e "    ${YELLOW}▶${RESET} ${name}${lock_info}"
  done
fi
[[ "$doing_count" -eq 0 ]] && echo -e "    ${DIM}(sem tasks ativas)${RESET}"

# ══════════════════════════════════════════════════════════════════════════════
# 4. RECENT RUNS — ultimas execucoes do scheduler
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Recent Runs${RESET}"

STATE_HOST="$zion_ephemeral/scheduler/state.json"
STATE_PY="$zion_cli_dir/src/lib/state_reader.py"
state_output=""

# Fonte 1: state.json direto no host
if [[ -f "$STATE_HOST" ]] && [[ -f "$STATE_PY" ]]; then
  state_output=$(python3 "$STATE_PY" "$STATE_HOST" 2>/dev/null) || true
fi

# Fonte 2: via docker exec com timeout (evita travar se container parado)
if [[ -z "$state_output" ]] && [[ -f "$STATE_PY" ]]; then
  puppy_running=$(OBSIDIAN_PATH="$zion_obsidian_path" \
    docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" ps --status running -q 2>/dev/null || true)
  if [[ -n "$puppy_running" ]]; then
    state_output=$(timeout 3s \
      docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" exec -T puppy \
      python3 -c "$(cat "$STATE_PY")" "/workspace/.ephemeral/scheduler/state.json" 2>/dev/null) || true
  fi
fi

if [[ -n "$state_output" ]]; then
  echo -e "$state_output"
else
  # Fallback: task.log.md
  TASK_LOG="${zion_obsidian_path}/agents/task.log.md"
  if [[ -f "$TASK_LOG" ]]; then
    recent=$(grep '^|' "$TASK_LOG" | grep -v '^| timestamp' | grep -v '^|---' | tail -10 | tac)
    if [[ -n "$recent" ]]; then
      while IFS='|' read -r _ ts task event model dur _; do
        ts=$(echo "$ts" | xargs 2>/dev/null)
        task=$(echo "$task" | xargs 2>/dev/null)
        event=$(echo "$event" | xargs 2>/dev/null)
        model=$(echo "$model" | xargs 2>/dev/null)
        dur=$(echo "$dur" | xargs 2>/dev/null)
        [[ -z "$ts" || -z "$task" ]] && continue
        r_icon="${YELLOW}▶${RESET}"
        [[ "$event" == *"done"* || "$event" == *"✔"* ]] && r_icon="${GREEN}✓${RESET}"
        [[ "$event" == *"fail"* || "$event" == *"✗"* ]] && r_icon="${RED}✗${RESET}"
        ts_epoch=$(date -d "$ts" +%s 2>/dev/null || echo "0")
        now_epoch=$(date +%s)
        diff_s=$((now_epoch - ts_epoch))
        if [[ "$ts_epoch" -gt 0 ]] && [[ "$diff_s" -ge 0 ]]; then
          if [[ "$diff_s" -lt 60 ]]; then ago="${diff_s}s ago"
          elif [[ "$diff_s" -lt 3600 ]]; then ago="$((diff_s / 60))min ago"
          elif [[ "$diff_s" -lt 86400 ]]; then ago="$((diff_s / 3600))h ago"
          else ago="$((diff_s / 86400))d ago"
          fi
        else
          ago="$ts"
        fi
        dur_str=""
        [[ -n "$dur" && "$dur" != "—" ]] && dur_str="  ${DIM}${dur}${RESET}"
        echo -e "  ${r_icon} $(printf '%-20s' "$task") ${ORANGE}$(printf '%-12s' "$ago")${RESET} ${DIM}${event}  ${model}${dur_str}${RESET}"
      done <<< "$recent"
    else
      echo -e "  ${DIM}(sem historico)${RESET}"
    fi
  else
    echo -e "  ${DIM}(sem historico)${RESET}"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# 5. SCHEDULED — tasks registradas no scheduler
# ══════════════════════════════════════════════════════════════════════════════
sched_dirs=("${zion_obsidian_path}/tasks/_scheduled" "${zion_obsidian_path}/tasks/recurring")
sched_count=0
sched_lines=""

for sdir in "${sched_dirs[@]}"; do
  [[ -d "$sdir" ]] || continue
  for tdir in "$sdir"/*/; do
    [[ -d "$tdir" ]] || continue
    tname=$(basename "$tdir")
    # Ler clock/interval do frontmatter
    cfg=""
    [[ -f "$tdir/TASK.md" ]] && cfg="$tdir/TASK.md"
    [[ -z "$cfg" && -f "$tdir/CLAUDE.md" ]] && cfg="$tdir/CLAUDE.md"
    clock="" model_t="" timeout_t=""
    if [[ -n "$cfg" ]]; then
      clock=$(sed -n '/^---$/,/^---$/{ /^clock:/{ s/^clock: *//; p; } }' "$cfg" 2>/dev/null | tr -d '[:space:]')
      model_t=$(sed -n '/^---$/,/^---$/{ /^model:/{ s/^model: *//; p; } }' "$cfg" 2>/dev/null | tr -d '[:space:]')
      timeout_t=$(sed -n '/^---$/,/^---$/{ /^timeout:/{ s/^timeout: *//; p; } }' "$cfg" 2>/dev/null | tr -d '[:space:]')
    fi
    clock="${clock:-every60}"
    model_t="${model_t:-haiku}"
    timeout_t="${timeout_t:-300}"
    sched_lines+="  ${DIM}⏲${RESET}  $(printf '%-20s' "$tname") ${DIM}${clock}  ${model_t}  ${timeout_t}s${RESET}\n"
    sched_count=$((sched_count + 1))
  done
done

if [[ "$sched_count" -gt 0 ]]; then
  echo ""
  echo -e "${BOLD}${CYAN}  Scheduled${RESET}  ${DIM}(${sched_count} tasks)${RESET}"
  echo -e "$sched_lines"
else
  echo ""
fi
