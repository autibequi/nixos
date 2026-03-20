# Status agregado: sessão zion + dockerized services + cota
zion_load_config

local RESET='\033[0m'
local BOLD='\033[1m'
local DIM='\033[2m'
local GREEN='\033[32m'
local RED='\033[31m'
local YELLOW='\033[33m'
local CYAN='\033[36m'
local MAGENTA='\033[35m'
local ORANGE='\033[38;5;214m'
local WHITE='\033[37m'
local BLUE='\033[34m'

echo -e "\n${BOLD}${MAGENTA}  Zion Status${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}\n"

# Cota
local usage_script="${ZION_ROOT:-$HOME/nixos/zion}/scripts/claude-ai-usage.sh"
[ -x "$usage_script" ] && "$usage_script" 2>/dev/null | tail -2 | sed 's/^/  /' || true
echo ""

if ! docker info >/dev/null 2>&1; then
  echo -e "  ${RED}sem acesso ao Docker${RESET}\n"
else
  # Larguras de coluna -- unificadas com dockerized
  local _A_UPTIME_W=7 _A_NAME_W=16 _A_PORTS_W=18

  # Stats cache (cpu/mem)
  local _sess_stats_cache
  _sess_stats_cache=$(docker stats --no-stream \
    --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || true)

  # Todos os containers leech (agent sessions + headless workers)
  local _all_leech_rows
  _all_leech_rows=$(docker ps -a \
    --filter "ancestor=claude-nix-sandbox" \
    --filter "name=leech" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
    | sort -u | grep -v "^$" || true)

  # Separa interactive (TTY=true) de background (TTY=false)
  local _agent_rows="" _bg_rows=""
  while IFS=$'\t' read -r _cn _cs _cp; do
    [[ -z "$_cn" ]] && continue
    local _tty
    _tty=$(docker inspect --format '{{.Config.Tty}}' "$_cn" 2>/dev/null || echo "true")
    if [[ "$_tty" == "true" ]]; then
      _agent_rows+="${_cn}"$'\t'"${_cs}"$'\t'"${_cp}"$'\n'
    else
      _bg_rows+="${_cn}"$'\t'"${_cs}"$'\t'"${_cp}"$'\n'
    fi
  done <<< "$_all_leech_rows"

  # Helper: formata linha de agente
  # Linha 1: PREFIX ICON UPTIME(7) NAME(16) PORTS(18=vazio) cpu CPU%(7) mem MEM
  # Linha 2: continuacao + 4 mounts-chave (mnt/obs/zion/logs) com cor
  _print_agent_row() {
    local pfx="$1" name="$2" status="$3" tc="${4:-└─}"
    local icon uptime_raw
    if echo "$status" | grep -qi "^up"; then
      icon="${GREEN}●${RESET}"
      uptime_raw=$(echo "$status" | sed -E 's/Up //i; s/ \(.*\)//; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/')
    else
      icon="${RED}○${RESET}"
      uptime_raw="stopped"
    fi
    local uptime_pad
    uptime_pad=$(printf "%-${_A_UPTIME_W}s" "$uptime_raw")

    # Nome curto padded
    local short="${name#zion-projects-leech-run-}"
    short="${short#zion-projects-}"
    local name_pad
    name_pad=$(printf "%-${_A_NAME_W}s" "$short")

    # Stats cpu/mem
    local cpu_str="" mem_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(echo "$_sess_stats_cache" | awk -F'\t' -v n="$name" '$1==n || $1 ~ n {print $2, $3, $4}' | head -1)
      if [[ -n "$raw_stats" ]]; then
        local cpu mem
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        cpu_str="${DIM}cpu ${YELLOW}$(printf "%-7s" "$cpu")${RESET}"
        mem_str="${DIM}  mem ${CYAN}${mem}${RESET}"
      fi
    fi

    # Ports vazio padded (agents usam host-network)
    local ports_pad
    ports_pad=$(printf "%-${_A_PORTS_W}s" "")

    # Linha principal
    echo -e "${pfx}${icon} ${ORANGE}${uptime_pad}${RESET}  ${WHITE}${name_pad}${RESET}  ${DIM}${ports_pad}${RESET}  ${cpu_str}${mem_str}"

    # Linha 2: 4 mounts-chave com cor (verde=conectado, vermelho=ausente)
    local dest_mounts
    dest_mounts=$(docker inspect --format '{{range .Mounts}}{{.Destination}} {{end}}' "$name" 2>/dev/null || true)
    local vols=()
    for v_entry in "/workspace/mnt:mnt" "/workspace/obsidian:obs" "/workspace/zion:zion" "/workspace/logs/docker:logs"; do
      local vp="${v_entry%%:*}" vn="${v_entry##*:}"
      if echo "$dest_mounts" | grep -qw "$vp"; then
        vols+=("${GREEN}${vn}${RESET}")
      else
        vols+=("${RED}${vn}${RESET}")
      fi
    done
    local cont_indent
    [[ "$tc" == "├─" ]] && cont_indent="  ${BLUE}│${RESET}    " || cont_indent="       "
    echo -e "${cont_indent}${DIM}$(IFS='  '; echo "${vols[*]}")${RESET}"
  }

  _print_agent_group() {
    local label="$1" rows="$2"
    local arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && arr+=("$line"); done <<< "$rows"
    local n="${#arr[@]}"
    [[ "$n" -eq 0 ]] && return

    local any_up=0
    echo "$rows" | grep -qi "	Up " && any_up=1
    local grp_icon; [[ "$any_up" -eq 1 ]] && grp_icon="${GREEN}●${RESET}" || grp_icon="${RED}○${RESET}"
    echo -e "${grp_icon} ${BOLD}${CYAN}${label}${RESET}"
    for i in "${!arr[@]}"; do
      IFS=$'\t' read -r _cn _cs _cp <<< "${arr[$i]}"
      local tc="├─"; [[ "$i" -eq "$((n - 1))" ]] && tc="└─"
      _print_agent_row "  ${BLUE}${tc}${RESET} " "$_cn" "$_cs" "$tc"
    done
    echo ""
  }

  _print_agent_group "agents" "$_agent_rows"
  _print_agent_group "background" "$_bg_rows"

  # Dockerized services — sem header separado, mesma lista
  source "${ZION_ROOT:-$HOME/nixos/zion}/cli/src/lib/docker_status_impl.sh" 2>/dev/null || true
  if declare -f _zion_dk_status >/dev/null 2>&1; then
    _zion_dk_status "" 1
  fi
  echo ""
fi
