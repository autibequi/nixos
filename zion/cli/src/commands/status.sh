# Status agregado do Zion: config, containers, services, puppy, tasks, repo.
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
icon_ok="${GREEN}✓${RESET}"
icon_fail="${RED}✗${RESET}"
icon_warn="${YELLOW}!${RESET}"

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

# key=value com cor
kv() {
  local label="$1" value="$2" color="${3:-$WHITE}"
  printf "  ${DIM}%-14s${RESET} ${color}%b${RESET}\n" "$label" "$value"
}

count_dirs() {
  local dir="$1"
  [[ -d "$dir" ]] && find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0"
}

# ── Header ─────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${MAGENTA}  Zion Status${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}\n"

# ══════════════════════════════════════════════════════════════════════════════
# 1. CONFIG — engine, model, keys
# ══════════════════════════════════════════════════════════════════════════════
echo -e "${BOLD}${CYAN}  Config${RESET}"

cfg_engine="${ZION_ENGINE:-${engine:-}}"
cfg_model="${ZION_MODEL:-${model:-}}"
[[ -n "$cfg_engine" ]] && kv "engine:" "$cfg_engine" "$GREEN" || kv "engine:" "(not set)" "$YELLOW"
[[ -n "$cfg_model" ]] && kv "model:" "$cfg_model" "$GREEN" || kv "model:" "(default)" "$DIM"

# API keys
key_line="  "
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  key_line+="${GREEN}ANTHROPIC${RESET} "
else
  key_line+="${RED}ANTHROPIC${RESET} "
fi
if [[ -n "${GH_TOKEN:-}" ]]; then
  key_line+="${GREEN}GH_TOKEN${RESET} "
else
  key_line+="${YELLOW}GH_TOKEN${RESET} "
fi
if [[ -n "${CURSOR_API_KEY:-}" ]]; then
  key_line+="${GREEN}CURSOR${RESET}"
else
  key_line+="${DIM}CURSOR${RESET}"
fi
echo -e "  ${DIM}keys:${RESET}         $key_line"

# Image
img_info=$(docker images claude-nix-sandbox --format "{{.Size}}\t{{.CreatedSince}}" 2>/dev/null | head -1)
if [[ -n "$img_info" ]]; then
  IFS=$'\t' read -r img_size img_age <<< "$img_info"
  kv "image:" "${img_size}  ${DIM}(${img_age})${RESET}" "$WHITE"
fi

# Rebuild needed?
if [[ -f "$zion_ephemeral/rebuild-docker-needed" ]]; then
  echo -e "  ${YELLOW}!${RESET} ${YELLOW}rebuild-docker-needed${RESET}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 2. REPO — git status
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Repo${RESET}"

if [[ -d "$zion_nixos_dir/.git" ]]; then
  repo_branch=$(git -C "$zion_nixos_dir" branch --show-current 2>/dev/null)
  repo_dirty=$(git -C "$zion_nixos_dir" status --porcelain 2>/dev/null | wc -l)
  repo_commit=$(git -C "$zion_nixos_dir" log -1 --format="%h %s" 2>/dev/null)
  repo_worktrees=$(git -C "$zion_nixos_dir" worktree list 2>/dev/null | wc -l)
  # Subtract 1 for the main worktree
  repo_worktrees=$((repo_worktrees - 1))
  [[ "$repo_worktrees" -lt 0 ]] && repo_worktrees=0

  dirty_str=""
  if [[ "$repo_dirty" -gt 0 ]]; then
    dirty_str="  ${YELLOW}(${repo_dirty} dirty)${RESET}"
  fi
  kv "branch:" "${repo_branch}${dirty_str}" "$GREEN"
  kv "commit:" "$repo_commit" "$DIM"
  [[ "$repo_worktrees" -gt 0 ]] && kv "worktrees:" "$repo_worktrees" "$ORANGE"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 3. SESSIONS — containers zion-*
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Sessions${RESET}"

# Format: name, status, ports, state (running/exited), command (to detect engine)
session_rows=$(docker ps -a --filter "name=zion-" \
  --format "{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.State}}\t{{.Command}}" 2>/dev/null \
  | grep -v "zion-dk-" || true)

session_up=0
session_dead=0

if [[ -z "$session_rows" ]]; then
  echo -e "  ${DIM}(nenhuma)${RESET}"
else
  session_orphan=0
  while IFS=$'\t' read -r name status ports state cmd; do
    [[ -z "$name" ]] && continue
    short="${name#zion-}"
    if [[ "$state" == "running" ]]; then
      # Check if agent is alive inside (claude, cursor, opencode)
      procs=$(docker exec "$name" ps -eo comm 2>/dev/null | grep -cE '(claude|cursor|opencode)' || true)
      procs="${procs:-0}"
      if [[ "$procs" -gt 0 ]]; then
        s_icon="$icon_running"
        session_up=$((session_up + 1))
      else
        s_icon="$icon_partial"
        session_orphan=$((session_orphan + 1))
      fi
    else
      s_icon="$icon_stopped"
      session_dead=$((session_dead + 1))
    fi
    row "  ${s_icon} " "$short" "$status" "$ports"
  done <<< "$session_rows"
  # Summary
  stale=$((session_dead + session_orphan))
  summary="  ${DIM}"
  [[ "$session_up" -gt 0 ]] && summary+="${session_up} active"
  [[ "$stale" -gt 0 ]] && summary+="  ${YELLOW}${stale} stale${RESET}${DIM} (zion clean to remove)"
  summary+="${RESET}"
  echo -e "$summary"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 4. DOCKER SERVICES — estrategia
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Docker Services${RESET}"

for svc in monolito bo-container front-student; do
  project=$(zion_docker_project_name "$svc")
  compose=$(zion_docker_compose_file "$svc" 2>/dev/null || echo "")

  main_rows=""
  if [[ -n "$compose" ]] && [[ -f "$compose" ]]; then
    main_rows=$(docker compose -f "$compose" -p "$project" ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)
  fi
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
# 5. PUPPY — worker persistente
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
# 6. TASKS — contagem por status
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}  Tasks${RESET}"

tasks_base="${zion_obsidian_path}/tasks"
t_doing=$(count_dirs "$tasks_base/doing")
t_backlog=$(count_dirs "$tasks_base/backlog")
t_sched=$(count_dirs "$tasks_base/_scheduled")
t_recur=$(count_dirs "$tasks_base/recurring")
t_done=$(count_dirs "$tasks_base/done")
t_cancel=$(count_dirs "$tasks_base/cancelled")

sched_total=$((t_sched + t_recur))

task_line="  "
[[ "$t_doing" -gt 0 ]] && task_line+="${YELLOW}${t_doing} doing${RESET}  " || task_line+="${DIM}0 doing${RESET}  "
[[ "$t_backlog" -gt 0 ]] && task_line+="${WHITE}${t_backlog} backlog${RESET}  " || task_line+="${DIM}0 backlog${RESET}  "
task_line+="${DIM}${sched_total} scheduled  ${t_done} done  ${t_cancel} cancelled${RESET}"
echo -e "$task_line"

# ══════════════════════════════════════════════════════════════════════════════
# 7. RECENT RUNS — ultimas execucoes do scheduler
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

# Fonte 2: via docker exec com timeout
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
# 8. SCHEDULED — tasks registradas
# ══════════════════════════════════════════════════════════════════════════════
sched_dirs=("${zion_obsidian_path}/tasks/_scheduled" "${zion_obsidian_path}/tasks/recurring")
sched_count=0
sched_lines=""

for sdir in "${sched_dirs[@]}"; do
  [[ -d "$sdir" ]] || continue
  for tdir in "$sdir"/*/; do
    [[ -d "$tdir" ]] || continue
    tname=$(basename "$tdir")
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
fi

# ══════════════════════════════════════════════════════════════════════════════
# 9. API USAGE — barra de uso (se disponivel)
# ══════════════════════════════════════════════════════════════════════════════
usage_file="$zion_ephemeral/usage-bar.txt"
if [[ -f "$usage_file" ]]; then
  usage_pct=$(grep '^pct=' "$usage_file" 2>/dev/null | cut -d= -f2)
  usage_used=$(grep '^used=' "$usage_file" 2>/dev/null | cut -d= -f2)
  usage_max=$(grep '^max=' "$usage_file" 2>/dev/null | cut -d= -f2)
  usage_updated=$(grep '^updated=' "$usage_file" 2>/dev/null | cut -d= -f2)
  usage_period=$(grep '^period=' "$usage_file" 2>/dev/null | cut -d= -f2)

  if [[ -n "$usage_pct" ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}  API Usage${RESET}"
    # Color based on percentage
    pct_num="${usage_pct%%%}"
    usage_color="$GREEN"
    [[ "$pct_num" -gt 50 ]] && usage_color="$YELLOW"
    [[ "$pct_num" -gt 80 ]] && usage_color="$RED"
    # Simple bar
    bar_width=20
    filled=$((pct_num * bar_width / 100))
    [[ "$filled" -gt "$bar_width" ]] && filled="$bar_width"
    empty=$((bar_width - filled))
    bar="${usage_color}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${DIM}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${RESET}"
    echo -e "  ${bar} ${usage_color}${usage_pct}${RESET}  ${DIM}\$${usage_used}/\$${usage_max}  ${usage_period}${RESET}"
    [[ -n "$usage_updated" ]] && echo -e "  ${DIM}updated: ${usage_updated}${RESET}"
  fi
fi

echo ""
