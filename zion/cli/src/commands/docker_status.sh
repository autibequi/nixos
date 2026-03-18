# Status dos servicos Docker.
zion_load_config

# Cores
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

service="${args[service]:-}"

# Extrai portas unicas no formato :PORT (remove duplicatas ipv4/ipv6)
format_ports() {
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

# Simplifica status: "Up 2 hours (healthy)" -> "2h  healthy"
format_status() {
  local s="$1"
  if echo "$s" | grep -qi "up"; then
    # extrai tempo
    local t
    t=$(echo "$s" | sed -E 's/Up //i; s/ \(.*\)//')
    t=$(echo "$t" | sed -E 's/ minutes?/min/; s/ hours?/h/; s/ days?/d/; s/ weeks?/w/')
    local healthy=""
    echo "$s" | grep -qi "healthy" && healthy=" ${GREEN}✓${RESET}"
    echo "${ORANGE}${t}${RESET}${healthy}"
  elif echo "$s" | grep -qi "exited"; then
    echo "${RED}exited${RESET}"
  else
    echo "${YELLOW}${s}${RESET}"
  fi
}

# Imprime: tempo  nome  :port1  :port2  (tudo na mesma linha, nome alinhado)
print_container_row() {
  local tree_pfx="$1" name="$2" status="$3" ports="$4"
  local TIME_W=9 NAME_W=14

  local status_str
  status_str=$(format_status "$status")

  local fmt_ports=""
  fmt_ports=$(format_ports "$ports")
  local ports_str=""
  [[ -n "$fmt_ports" ]] && ports_str="  ${DIM}${fmt_ports}${RESET}"

  local padded_name
  padded_name=$(printf "%-${NAME_W}s" "$name")

  echo -e "${tree_pfx}$(printf "%-${TIME_W}b" "$status_str")  ${WHITE}${padded_name}${RESET}${ports_str}"
}

print_service_tree() {
  local svc="$1"
  local project compose
  project=$(zion_docker_project_name "$svc")
  compose=$(zion_docker_compose_file "$svc")

  local running deps_running
  running=$(docker compose -f "$compose" -p "$project" ps --status running 2>/dev/null | tail -n +2 | wc -l)
  deps_running=$(docker compose -p "${project}-deps" ps --status running 2>/dev/null | tail -n +2 | wc -l)
  local total=$((running + deps_running))

  # Header
  if [[ "$total" -eq 0 ]]; then
    echo -e "${icon_stopped} ${BOLD}${CYAN}${svc}${RESET}  ${DIM}parado${RESET}"
    return
  fi

  local svc_icon="$icon_running"
  [[ "$running" -eq 0 || "$deps_running" -eq 0 ]] && svc_icon="$icon_partial"

  local has_deps=0
  dep_rows_raw=$(docker compose -p "${project}-deps" ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
  dep_lines=()
  while IFS= read -r line; do [[ -n "$line" ]] && dep_lines+=("$line"); done <<< "$dep_rows_raw"
  [[ "${#dep_lines[@]}" -gt 0 ]] && has_deps=1

  echo -e "${svc_icon} ${BOLD}${CYAN}${svc}${RESET}"

  # App containers
  local main_rows
  main_rows=$(docker compose -f "$compose" -p "$project" ps --format "{{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
  if [[ -n "$main_rows" ]]; then
    local branch_char="├─"
    [[ "$has_deps" -eq 0 ]] && branch_char="└─"
    echo -e "  ${BLUE}${branch_char}${RESET} ${BOLD}${svc}${RESET}"
    local cont_line="│  "
    [[ "$has_deps" -eq 0 ]] && cont_line="   "
    while IFS=$'\t' read -r name status ports; do
      [[ -z "$name" ]] && continue
      local short="${name##${project}-}"
      print_container_row "  ${cont_line}└─ " "$short" "$status" "$ports"
    done <<< "$main_rows"
  fi

  # Deps
  if [[ "$has_deps" -eq 1 ]]; then
    echo -e "  ${BLUE}└─${RESET} ${BOLD}deps${RESET}"
    local total_deps="${#dep_lines[@]}"
    local i=0
    for row in "${dep_lines[@]}"; do
      i=$((i + 1))
      IFS=$'\t' read -r name status ports <<< "$row"
      [[ -z "$name" ]] && continue
      local short="${name##zion-dk-${svc}-}"
      local tc="├─" port_cont="│  "
      if [[ "$i" -eq "$total_deps" ]]; then tc="└─"; port_cont="   "; fi
      print_container_row "     ${tc} " "$short" "$status" "$ports"
    done
  fi
}

if [[ -n "$service" ]]; then
  print_service_tree "$service"
else
  echo -e "\n${BOLD}${MAGENTA}  Zion Docker${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}\n"
  services_list="monolito bo-container front-student"
  count=0
  total_svcs=$(echo "$services_list" | wc -w)
  for svc in $services_list; do
    count=$((count + 1))
    print_service_tree "$svc"
    [[ "$count" -lt "$total_svcs" ]] && echo ""
  done
  echo ""
fi
