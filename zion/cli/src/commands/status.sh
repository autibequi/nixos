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

# ── Cota ──────────────────────────────────────────────────────────────────
local usage_script="${ZION_ROOT:-$HOME/nixos/zion}/scripts/claude-ai-usage.sh"
[ -x "$usage_script" ] && "$usage_script" 2>/dev/null | tail -2 | sed 's/^/  /' || true
echo ""

if ! docker info >/dev/null 2>&1; then
  echo -e "  ${RED}sem acesso ao Docker${RESET}\n"
else
  # Stats cache para sessions (cpu/mem)
  local _sess_stats_cache
  _sess_stats_cache=$(docker stats --no-stream \
    --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || true)

  # ── Session containers ────────────────────────────────────────────────────
  local session_rows
  session_rows=$(docker ps -a \
    --filter "ancestor=claude-nix-sandbox" \
    --filter "name=leech" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
    | sort -u | grep -v "^$" || true)

  # Helper: formata uma linha de container de sessão
  _print_session_row() {
    local pfx="$1" name="$2" status="$3" ports="$4"
    local icon uptime=""
    if echo "$status" | grep -qi "^up"; then
      icon="${GREEN}●${RESET}"
      uptime=$(echo "$status" | sed -E 's/Up //i; s/ \(.*\)//; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/')
    else
      icon="${RED}○${RESET}"
    fi

    # Portas
    local ports_str=""
    if [[ -n "$ports" ]]; then
      local fmt_ports
      fmt_ports=$(echo "$ports" \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+->[0-9]+' \
        | grep -oE ':[0-9]+->' | sed 's/->//' | sort -u \
        | tr '\n' '  ' | sed 's/  $//')
      [[ -n "$fmt_ports" ]] && ports_str="  ${DIM}${fmt_ports}${RESET}"
    fi

    # Stats cpu/mem
    local stats_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(echo "$_sess_stats_cache" | awk -F'\t' -v n="$name" '$1==n || $1 ~ n {print $2, $3, $4}' | head -1)
      if [[ -n "$raw_stats" ]]; then
        local cpu mem
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        stats_str="  ${DIM}cpu ${YELLOW}${cpu}${RESET}${DIM}  mem ${CYAN}${mem}${RESET}"
      fi
    fi

    # Volumes conectados
    local mounts
    mounts=$(docker inspect --format '{{range .Mounts}}{{.Destination}} {{end}}' "$name" 2>/dev/null || true)
    local vols=()
    for v_entry in "/workspace/mnt:mnt" "/workspace/obsidian:obs" "/workspace/zion:zion" "/workspace/logs/docker:logs"; do
      local vp="${v_entry%%:*}" vn="${v_entry##*:}"
      if echo "$mounts" | grep -qw "$vp"; then
        vols+=("${GREEN}${vn}✓${RESET}")
      else
        vols+=("${RED}${vn}✗${RESET}")
      fi
    done
    local vol_str="  $(IFS=' '; echo "${vols[*]}")"

    # Encurta nome: remove prefixo "zion-projects-leech-run-"
    local short="${name#zion-projects-leech-run-}"
    short="${short#zion-projects-}"
    echo -e "${pfx}${icon} ${WHITE}${short}${RESET}  ${ORANGE}${uptime}${RESET}${ports_str}${stats_str}${vol_str}"
  }

  # Sessões ativas (leech)
  local leech_arr=()
  while IFS= read -r line; do [[ -n "$line" ]] && leech_arr+=("$line"); done <<< "$session_rows"
  local n_leech="${#leech_arr[@]}"

  if [[ "$n_leech" -gt 0 ]]; then
    local any_leech_up=0
    echo "$session_rows" | grep -qi "	Up " && any_leech_up=1
    local leech_icon; [[ "$any_leech_up" -eq 1 ]] && leech_icon="${GREEN}●${RESET}" || leech_icon="${RED}○${RESET}"
    echo -e "${leech_icon} ${BOLD}${CYAN}sessions${RESET}"
    for i in "${!leech_arr[@]}"; do
      IFS=$'\t' read -r name status ports <<< "${leech_arr[$i]}"
      local tc="├─"; [[ "$i" -eq "$((n_leech - 1))" ]] && tc="└─"
      _print_session_row "  ${BLUE}${tc}${RESET} " "$name" "$status" "$ports"
    done
    echo ""
  fi

  # ── Dockerized services ──────────────────────────────────────────────────
  echo -e "${BOLD}${CYAN}  Dockerized${RESET}\n"
  source "${ZION_ROOT:-$HOME/nixos/zion}/cli/src/lib/docker_status_impl.sh" 2>/dev/null || true
  if declare -f _zion_dk_status >/dev/null 2>&1; then
    _zion_dk_status "" 1  # 1 = no_header
  fi
  echo ""
fi
