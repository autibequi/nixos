# docker_status_impl.sh — status dos servicos Docker.
#
# Uso: _zion_dk_status <service>
# Se service for vazio, mostra todos os servicos.

_zion_dk_status() {
  local service="${1:-}"

  # Cores
  local RESET='\033[0m'
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local GREEN='\033[32m'
  local RED='\033[31m'
  local YELLOW='\033[33m'
  local CYAN='\033[36m'
  local BLUE='\033[34m'
  local MAGENTA='\033[35m'
  local WHITE='\033[37m'
  local ORANGE='\033[38;5;214m'

  local icon_running="${GREEN}●${RESET}"
  local icon_stopped="${RED}○${RESET}"
  local icon_partial="${YELLOW}◐${RESET}"

  # Cache de stats: "NOME cpu mem" por linha — buscado uma vez
  local _stats_cache
  _stats_cache=$(docker stats --no-stream \
    --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || true)

  # Lookup cpu/mem para um container
  stats_for() {
    local cname="$1"
    echo "$_stats_cache" | awk -F'\t' -v n="$cname" '$1==n {print $2, $3}' | head -1
  }

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

  # Imprime: uptime  nome  :ports  cpu  mem
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

    # Stats (cpu/mem) — só se container estiver up
    local stats_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(stats_for "$name")
      if [[ -z "$raw_stats" ]]; then
        # tenta com prefixo do projeto
        local full_name
        full_name=$(echo "$_stats_cache" | awk -F'\t' -v n="$name" '$1 ~ n {print $1}' | head -1)
        [[ -n "$full_name" ]] && raw_stats=$(stats_for "$full_name")
      fi
      if [[ -n "$raw_stats" ]]; then
        local cpu mem
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        stats_str="  ${DIM}cpu ${YELLOW}${cpu}${RESET}${DIM}  mem ${CYAN}${mem}${RESET}"
      fi
    fi

    echo -e "${tree_pfx}$(printf "%-${TIME_W}b" "$status_str")  ${WHITE}${padded_name}${RESET}${ports_str}${stats_str}"
  }

  # all_dk_rows: cache unico de todos os containers zion-dk-* (evita N chamadas docker ps)
  local _all_dk_rows
  _all_dk_rows=$(docker ps -a --filter "name=zion-dk-" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)

  print_service_tree() {
    local svc="$1"
    local project
    project=$(zion_docker_project_name "$svc")  # zion-dk-<svc>

    # Separa main (nao deps) de deps — baseado em nome, nao em label compose
    local main_rows deps_rows
    main_rows=$(echo "$_all_dk_rows" | grep -E "^${project}-" | grep -vE "^${project}-deps-" || true)
    deps_rows=$(echo "$_all_dk_rows"  | grep -E "^${project}-deps-" || true)

    local any_rows="${main_rows}${deps_rows}"
    if [[ -z "$any_rows" ]]; then
      echo -e "${icon_stopped} ${BOLD}${CYAN}${svc}${RESET}  ${DIM}parado${RESET}"
      return
    fi

    # Icone: verde se algum main esta up, amarelo se so deps, vermelho se tudo exited
    local svc_icon="$icon_stopped"
    echo "$main_rows" | grep -qi "	Up " && svc_icon="$icon_running"
    [[ "$svc_icon" == "$icon_stopped" ]] && \
      echo "$deps_rows" | grep -qi "	Up " && svc_icon="$icon_partial"

    local has_deps=0
    [[ -n "$deps_rows" ]] && has_deps=1

    echo -e "${svc_icon} ${BOLD}${CYAN}${svc}${RESET}"

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
    local services_list="monolito bo-container front-student"
    local count=0
    local total_svcs
    total_svcs=$(echo "$services_list" | wc -w)
    for svc in $services_list; do
      count=$((count + 1))
      print_service_tree "$svc"
      [[ "$count" -lt "$total_svcs" ]] && echo ""
    done
    echo ""
  fi
}
