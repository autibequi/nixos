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
  local jgid
  jgid=$(getent group systemd-journal 2>/dev/null | cut -d: -f3)

  # ── Session containers ────────────────────────────────────────────────────
  local session_rows
  session_rows=$(docker ps -a \
    --filter "ancestor=claude-nix-sandbox" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
    | sort -u | grep -v "^$" || true)

  # Separa leech (sessões ativas) de puppy/legacy
  local leech_rows other_rows
  leech_rows=$(echo "$session_rows" | grep "leech" || true)
  other_rows=$(echo "$session_rows" | grep -v "leech" | grep -v "^$" || true)

  # Helper: formata uma linha de container de sessão
  _print_session_row() {
    local pfx="$1" name="$2" status="$3"
    local icon uptime="" gid_str=""
    if echo "$status" | grep -qi "^up"; then
      icon="${GREEN}●${RESET}"
      uptime=$(echo "$status" | sed -E 's/Up //i; s/ \(.*\)//; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/')
    else
      icon="${RED}○${RESET}"
    fi
    if [[ -n "$jgid" ]]; then
      local grps
      grps=$(docker inspect --format '{{join .HostConfig.GroupAdd ","}}' "$name" 2>/dev/null || true)
      if echo "$grps" | grep -qw "$jgid"; then
        gid_str="  ${GREEN}journal✓${RESET}"
      else
        gid_str="  ${RED}journal✗${RESET}"
      fi
    fi
    # Encurta nome: remove prefixo "zion-projects-leech-run-"
    local short="${name#zion-projects-leech-run-}"
    short="${short#zion-projects-}"
    echo -e "${pfx}${icon} ${WHITE}${short}${RESET}  ${ORANGE}${uptime}${RESET}${gid_str}"
  }

  # Sessões ativas (leech)
  local leech_arr=()
  while IFS= read -r line; do [[ -n "$line" ]] && leech_arr+=("$line"); done <<< "$leech_rows"
  local n_leech="${#leech_arr[@]}"

  if [[ "$n_leech" -gt 0 ]]; then
    local any_leech_up=0
    echo "$leech_rows" | grep -qi "	Up " && any_leech_up=1
    local leech_icon; [[ "$any_leech_up" -eq 1 ]] && leech_icon="${GREEN}●${RESET}" || leech_icon="${RED}○${RESET}"
    echo -e "${leech_icon} ${BOLD}${CYAN}sessions${RESET}  ${DIM}JOURNAL_GID: ${jgid:-(?)}, recrie com zion new se ✗${RESET}"
    for i in "${!leech_arr[@]}"; do
      IFS=$'\t' read -r name status ports <<< "${leech_arr[$i]}"
      local tc="├─"; [[ "$i" -eq "$((n_leech - 1))" ]] && tc="└─"
      _print_session_row "  ${BLUE}${tc}${RESET} " "$name" "$status"
    done
    echo ""
  fi

  # Puppy / legacy (parados ou não-leech)
  if [[ -n "$other_rows" ]]; then
    local other_arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && other_arr+=("$line"); done <<< "$other_rows"
    local n_other="${#other_arr[@]}"
    local any_other_up=0
    echo "$other_rows" | grep -qi "	Up " && any_other_up=1
    local other_icon; [[ "$any_other_up" -eq 1 ]] && other_icon="${GREEN}●${RESET}" || other_icon="${RED}○${RESET}"
    echo -e "${other_icon} ${BOLD}${CYAN}puppy${RESET}"
    for i in "${!other_arr[@]}"; do
      IFS=$'\t' read -r name status ports <<< "${other_arr[$i]}"
      local tc="├─"; [[ "$i" -eq "$((n_other - 1))" ]] && tc="└─"
      _print_session_row "  ${BLUE}${tc}${RESET} " "$name" "$status"
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
