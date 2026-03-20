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

  # Larguras de coluna — unificadas com a sessao de agents
  local TIME_W=7    # uptime
  local NAME_W=16   # nome do container
  local PORTS_W=18  # portas (string padded)

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
    [[ -z "$raw" ]] && echo "" && return
    echo "$raw" \
      | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+->[0-9]+' \
      | grep -oE ':[0-9]+->' \
      | sed 's/->//' \
      | sort -u \
      | tr '\n' ' ' \
      | sed 's/ $//'
  }

  # Bind mounts — mostra todos os não-sistema (exclui /proc /sys /dev /run /etc)
  format_mounts() {
    local cname="$1"
    local entries
    entries=$(docker inspect \
      --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}->{{.Destination}} {{end}}{{end}}' \
      "$cname" 2>/dev/null || true)
    local result=()
    for entry in $entries; do
      local src="${entry%%->*}"
      local dest="${entry##*->}"
      # Exclui paths de sistema
      echo "$src" | grep -qE '^/(proc|sys|dev|run/|var/run|etc/)' && continue
      # Usa basename do destino como label (mais informativo para o contexto do container)
      local label="${dest##*/}"
      [[ -z "$label" || "$dest" == "/" ]] && label="$src"
      result+=("$label")
    done
    if [[ "${#result[@]}" -gt 0 ]]; then
      printf '%s\n' "${result[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//'
    fi
  }

  # Simplifica status: "Up 2 hours (healthy)" -> "2h ✓"
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

  # Imprime linha unificada: icon  uptime  nome  ports  cpu  mem  mounts
  # Mesmo formato das linhas de agents (icon + UPTIME(7) + NAME(16) + PORTS(18) + cpu + mem + mounts)
  print_container_row() {
    local tree_pfx="$1" name="$2" status="$3" ports="$4" full_name="${5:-$2}"

    # Icon: ●/○ baseado no status (running vs stopped)
    local row_icon
    if echo "$status" | grep -qi "^up"; then
      row_icon="${GREEN}●${RESET}"
    else
      row_icon="${RED}○${RESET}"
    fi

    local status_str
    status_str=$(format_status "$status")

    # Portas: extrair e pad para PORTS_W
    local raw_ports
    raw_ports=$(format_ports "$ports")
    local ports_padded
    ports_padded=$(printf "%-${PORTS_W}s" "$raw_ports")
    local ports_str="${DIM}${ports_padded}${RESET}"

    # Nome padded
    local padded_name
    padded_name=$(printf "%-${NAME_W}s" "$name")

    # Stats (cpu/mem) — só se container estiver up
    local stats_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(stats_for "$name")
      if [[ -z "$raw_stats" ]]; then
        local full_name
        full_name=$(echo "$_stats_cache" | awk -F'\t' -v n="$name" '$1 ~ n {print $1}' | head -1)
        [[ -n "$full_name" ]] && raw_stats=$(stats_for "$full_name")
      fi
      if [[ -n "$raw_stats" ]]; then
        local cpu mem
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        stats_str="${DIM}cpu ${YELLOW}$(printf "%-7s" "$cpu")${RESET}${DIM}  mem ${CYAN}${mem}${RESET}"
      fi
    fi

    # Mounts
    local mnt_str=""
    if echo "$status" | grep -qi "^up"; then
      local mnt_names
      mnt_names=$(format_mounts "$full_name")
      [[ -n "$mnt_names" ]] && mnt_str="  ${DIM}${mnt_names}${RESET}"
    fi

    echo -e "${tree_pfx}${row_icon} $(printf "%-${TIME_W}b" "$status_str")  ${WHITE}${padded_name}${RESET}  ${ports_str}  ${stats_str}${mnt_str}"
  }

  # all_dk_rows: cache unico de todos os containers zion-dk-* (evita N chamadas docker ps)
  local _all_dk_rows
  _all_dk_rows=$(docker ps -a --filter "name=zion-dk-" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)

  print_service_tree() {
    local svc="$1"
    local project
    project=$(zion_docker_project_name "$svc")  # zion-dk-<svc>

    # Separa main (nao deps, nao worktrees) de deps — baseado em nome
    local main_rows deps_rows
    main_rows=$(echo "$_all_dk_rows" | grep -E "^${project}-" | grep -vE "^${project}-deps-" | grep -vE "^${project}-wt-" || true)
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

    # Lê main em array para usar branch chars corretos (├─ vs └─)
    local main_arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && main_arr+=("$line"); done <<< "$main_rows"

    local deps_arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && deps_arr+=("$line"); done <<< "$deps_rows"

    local total_main="${#main_arr[@]}"
    local total_deps="${#deps_arr[@]}"

    # Main containers — direto sob o header do serviço (sem label intermediário)
    for i in "${!main_arr[@]}"; do
      IFS=$'\t' read -r name status ports <<< "${main_arr[$i]}"
      [[ -z "$name" ]] && continue
      local short="${name##${project}-}"
      local tc="├─"
      [[ "$has_deps" -eq 0 && "$i" -eq "$((total_main - 1))" ]] && tc="└─"
      print_container_row "  ${BLUE}${tc}${RESET} " "$short" "$status" "$ports" "$name"
    done

    # Deps
    if [[ "$has_deps" -eq 1 ]]; then
      echo -e "  ${BLUE}└─${RESET} ${BOLD}deps${RESET}"
      for i in "${!deps_arr[@]}"; do
        IFS=$'\t' read -r name status ports <<< "${deps_arr[$i]}"
        [[ -z "$name" ]] && continue
        local short="${name##${project}-deps-}"
        local tc="├─"
        [[ "$i" -eq "$((total_deps - 1))" ]] && tc="└─"
        print_container_row "     ${tc} " "$short" "$status" "$ports" "$name"
      done
    fi
  }

  if [[ -n "$service" ]]; then
    print_service_tree "$service"
  else
    local no_header="${2:-0}"
    [[ "$no_header" -eq 0 ]] && echo -e "\n${BOLD}${MAGENTA}  Zion Docker${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}\n"
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
