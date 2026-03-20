# docker_status_impl.sh — status dos servicos Docker.
#
# Uso: _zion_dk_status <service>
# Se service for vazio, mostra todos os servicos.
# Usa _ZION_SHARED_STATS e _ZION_SHARED_DK_ROWS se disponíveis (evita refetch).

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

  # Larguras de coluna — unificadas com agents
  local TIME_W=7    # uptime
  local NAME_W=16   # nome do container
  local PORTS_W=18  # portas (string padded)

  # Usa cache compartilhado se disponível, senão busca
  local _stats_cache
  if [[ -n "${_ZION_SHARED_STATS:-}" ]]; then
    _stats_cache="$_ZION_SHARED_STATS"
  else
    _stats_cache=$(docker stats --no-stream \
      --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || true)
  fi

  # all_dk_rows: usa cache compartilhado se disponível
  local _all_dk_rows
  if [[ -n "${_ZION_SHARED_DK_ROWS:-}" ]]; then
    _all_dk_rows="$_ZION_SHARED_DK_ROWS"
  else
    _all_dk_rows=$(docker ps -a --filter "name=zion-dk-" \
      --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)
  fi

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

  # Batch inspect de mounts para todos os containers dk (um único docker inspect)
  local _dk_names=()
  while IFS=$'\t' read -r _n _ _; do
    [[ -n "$_n" ]] && _dk_names+=("$_n")
  done <<< "$_all_dk_rows"

  # Formato: "name|src1->dest1 src2->dest2 ..."
  local _mounts_cache=""
  if [[ "${#_dk_names[@]}" -gt 0 ]]; then
    _mounts_cache=$(docker inspect \
      --format '{{.Name}}|{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}->{{.Destination}} {{end}}{{end}}' \
      "${_dk_names[@]}" 2>/dev/null | sed 's|^/||')
  fi

  # Bind mounts relevantes — do cache batch
  format_mounts() {
    local cname="$1"
    local entries
    entries=$(echo "$_mounts_cache" | awk -F'|' -v n="$cname" '$1==n {print $2}' | head -1)
    local result=()
    for entry in $entries; do
      local src="${entry%%->*}"
      local dest="${entry##*->}"
      echo "$src" | grep -qE '^/home/' || continue
      local label="${src##*/}"
      result+=("$label")
    done
    if [[ "${#result[@]}" -gt 0 ]]; then
      printf '%s\n' "${result[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//' | sed 's/ /  /g'
    fi
  }

  # Simplifica status: texto puro, sem ANSI
  format_status() {
    local s="$1"
    if echo "$s" | grep -qi "up"; then
      local t
      t=$(echo "$s" | sed -E 's/Up //i; s/ \(.*\)//')
      t=$(echo "$t" | sed -E 's/ seconds?/s/; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/; s/ weeks?/w/')
      echo "$t"
    elif echo "$s" | grep -qi "exited"; then
      echo "exited"
    else
      echo "$s"
    fi
  }

  # Imprime linha de container + segunda linha com mounts
  print_container_row() {
    local tree_pfx="$1" name="$2" status="$3" ports="$4" full_name="${5:-$2}" tc="${6:-└─}" extra="${7:-}"

    local row_icon
    if echo "$status" | grep -qi "^up"; then
      row_icon="${GREEN}●${RESET}"
    else
      row_icon="${RED}○${RESET}"
    fi

    # Uptime: pad no texto puro, depois cor
    local uptime_raw uptime_pad uptime_colored
    uptime_raw=$(format_status "$status")
    uptime_pad=$(printf "%-${TIME_W}s" "$uptime_raw")
    if echo "$status" | grep -qi "^up"; then
      uptime_colored="${ORANGE}${uptime_pad}${RESET}"
    elif echo "$status" | grep -qi "exited"; then
      uptime_colored="${RED}${uptime_pad}${RESET}"
    else
      uptime_colored="${YELLOW}${uptime_pad}${RESET}"
    fi

    local raw_ports ports_padded ports_str
    raw_ports=$(format_ports "$ports")
    ports_padded=$(printf "%-${PORTS_W}s" "$raw_ports")
    ports_str="${DIM}${ports_padded}${RESET}"

    local padded_name
    padded_name=$(printf "%-${NAME_W}s" "$name")

    local stats_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(stats_for "$name")
      if [[ -z "$raw_stats" ]]; then
        local _fname
        _fname=$(echo "$_stats_cache" | awk -F'\t' -v n="$full_name" '$1 ~ n {print $1}' | head -1)
        [[ -n "$_fname" ]] && raw_stats=$(stats_for "$_fname")
      fi
      if [[ -n "$raw_stats" ]]; then
        local cpu mem
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        stats_str="${DIM}cpu ${YELLOW}$(printf "%-7s" "$cpu")${RESET}${DIM}  mem ${CYAN}${mem}${RESET}"
      fi
    fi

    echo -e "${tree_pfx}${row_icon} ${uptime_colored}  ${WHITE}${padded_name}${RESET}  ${ports_str}  ${stats_str}${extra}"

    local cont_indent
    [[ "$tc" == "├─" ]] && cont_indent="  ${BLUE}│${RESET}    " || cont_indent="       "

    if echo "$status" | grep -qi "^up"; then
      local mnt_names
      mnt_names=$(format_mounts "$full_name")
      if [[ -n "$mnt_names" ]]; then
        echo -e "${cont_indent}${GREEN}${mnt_names}${RESET}"
      fi
    elif echo "$status" | grep -qi "exited"; then
      local err_lines
      err_lines=$(docker logs --tail 5 "$full_name" 2>&1 | tail -5)
      if [[ -n "$err_lines" ]]; then
        while IFS= read -r _eline; do
          echo -e "${cont_indent}${RED}${DIM}${_eline}${RESET}"
        done <<< "$err_lines"
      fi
    fi
  }

  print_service_tree() {
    local svc="$1"
    local project
    project=$(zion_docker_project_name "$svc")  # zion-dk-<svc>

    local main_rows deps_rows
    main_rows=$(echo "$_all_dk_rows" | grep -E "^${project}-" | grep -vE "^${project}-deps-" | grep -vE "^${project}-wt-" || true)
    deps_rows=$(echo "$_all_dk_rows"  | grep -E "^${project}-deps-" || true)

    # Cursor: ▶ se este servico estiver selecionado (via dynamic scoping)
    local _is_selected=0
    [[ "${_cursor_svc:-}" == "$svc" ]] && _is_selected=1

    local any_rows="${main_rows}${deps_rows}"
    if [[ -z "$any_rows" ]]; then
      local _pfx_icon="$icon_stopped"
      [[ "$_is_selected" -eq 1 ]] && _pfx_icon="${CYAN}▶${RESET}"
      local _pending_env="${_svc_env[$svc]:-sand}"
      # Mostrar acao pendente (iniciando/parando) se recente
      local _act="${_svc_action[$svc]:-}" _act_ts="${_svc_action_ts[$svc]:-0}"
      local _now_act; _now_act=$(date +%s)
      if [[ -n "$_act" && $(( _now_act - _act_ts )) -lt 15 ]]; then
        echo -e "${_pfx_icon} ${BOLD}${CYAN}${svc}${RESET}  ${DIM}${YELLOW}${_pending_env}${RESET}  ${YELLOW}${_act}...${RESET}"
      else
        echo -e "${_pfx_icon} ${BOLD}${CYAN}${svc}${RESET}  ${DIM}${YELLOW}${_pending_env}${RESET}  ${DIM}parado${RESET}"
      fi
      return
    fi

    local svc_icon="$icon_stopped"
    echo "$main_rows" | grep -qi "	Up " && svc_icon="$icon_running"
    [[ "$svc_icon" == "$icon_stopped" ]] && \
      echo "$deps_rows" | grep -qi "	Up " && svc_icon="$icon_partial"

    local prefix_icon="$svc_icon"
    [[ "$_is_selected" -eq 1 ]] && prefix_icon="${CYAN}▶${RESET}"

    local has_deps=0
    [[ -n "$deps_rows" ]] && has_deps=1

    # ENV (cabeçalho) e branch (linha do app) — com cache TTL 30s
    local env_label="" branch_label=""
    if echo "$main_rows" | grep -qi "	Up "; then
      local _now_meta; _now_meta=$(date +%s)
      local _cached_ts="${_svc_meta_ts[$svc]:-0}"
      if [[ $(( _now_meta - _cached_ts )) -gt 30 ]]; then
        # Re-fetch: env vars + branch
        local _app_cname="${project}-app"
        local _env_vars
        _env_vars=$(docker inspect --format '{{range .Config.Env}}{{.}}{{"\n"}}{{end}}' "$_app_cname" 2>/dev/null)
        # Tenta vars conhecidas de ambiente na ordem de prioridade
        env_label=$(echo "$_env_vars" | grep -E '^(APP_ENV|RAILS_ENV|MIX_ENV|ENVIRONMENT|APP_ENVIRONMENT)=' \
          | sed 's/^[^=]*=//' | head -1)
        # Fallback por valor: qualquer var cujo valor seja sand/prod/local/staging/development
        if [[ -z "$env_label" ]]; then
          env_label=$(echo "$_env_vars" \
            | grep -E '=(sand|sandbox|prod|production|local|staging|development)$' \
            | grep -vE '^(HOME|HOSTNAME|PATH|TERM|SHELL|USER|LANG|PWD|LC_|SHLVL)' \
            | sed 's/^[^=]*=//' | head -1)
        fi
        local _svc_dir
        _svc_dir=$(zion_docker_service_dir "$svc" 2>/dev/null || true)
        [[ -n "$_svc_dir" && -d "$_svc_dir" ]] && \
          branch_label=$(git -C "$_svc_dir" branch --show-current 2>/dev/null || true)
        # Salva no cache (via dynamic scoping — arrays declarados em status.sh)
        _svc_env_label[$svc]="$env_label"
        _svc_branch_label[$svc]="$branch_label"
        _svc_meta_ts[$svc]="$_now_meta"
      else
        env_label="${_svc_env_label[$svc]:-}"
        branch_label="${_svc_branch_label[$svc]:-}"
      fi
    fi

    # Feedback de acao pendente (parando...)
    local _act="${_svc_action[$svc]:-}" _act_ts="${_svc_action_ts[$svc]:-0}"
    local _now_act2; _now_act2=$(date +%s)
    local _act_label=""
    [[ -n "$_act" && $(( _now_act2 - _act_ts )) -lt 15 ]] && \
      _act_label="  ${YELLOW}${_act}...${RESET}"

    # Cabeçalho: nome + env solto (sem colchetes) + acao
    local meta=""
    [[ -n "$env_label" ]] && meta="  ${DIM}${env_label}${RESET}"
    echo -e "${prefix_icon} ${BOLD}${CYAN}${svc}${RESET}${meta}${_act_label}"

    local main_arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && main_arr+=("$line"); done <<< "$main_rows"

    local deps_arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && deps_arr+=("$line"); done <<< "$deps_rows"

    local total_main="${#main_arr[@]}"
    local total_deps="${#deps_arr[@]}"

    for i in "${!main_arr[@]}"; do
      IFS=$'\t' read -r name status ports <<< "${main_arr[$i]}"
      [[ -z "$name" ]] && continue
      local short="${name##${project}-}"
      local tc="├─"
      [[ "$has_deps" -eq 0 && "$i" -eq "$((total_main - 1))" ]] && tc="└─"
      # Branch aparece na linha do container app, junto com CPU
      local _row_extra=""
      [[ "$short" == "app" && -n "$branch_label" ]] && \
        _row_extra="  ${DIM}[${branch_label}]${RESET}"
      print_container_row "  ${BLUE}${tc}${RESET} " "$short" "$status" "$ports" "$name" "$tc" "$_row_extra"
    done

    if [[ "$has_deps" -eq 1 ]]; then
      echo -e "  ${BLUE}└─${RESET} ${BOLD}deps${RESET}"
      for i in "${!deps_arr[@]}"; do
        IFS=$'\t' read -r name status ports <<< "${deps_arr[$i]}"
        [[ -z "$name" ]] && continue
        local short="${name##${project}-deps-}"
        local tc="├─"
        [[ "$i" -eq "$((total_deps - 1))" ]] && tc="└─"
        print_container_row "     ${tc} " "$short" "$status" "$ports" "$name" "$tc"
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
