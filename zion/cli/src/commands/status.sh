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

# ── Session containers ─────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}  Session${RESET}"

if ! docker info >/dev/null 2>&1; then
  echo -e "  ${RED}sem acesso ao Docker${RESET}\n"
else
  local jgid
  jgid=$(getent group systemd-journal 2>/dev/null | cut -d: -f3)
  echo -e "  ${DIM}JOURNAL_GID: ${jgid:-(nao detectado)}${RESET}"
  echo ""

  local session_rows
  session_rows=$(
    { docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" \
        --filter "ancestor=claude-nix-sandbox" 2>/dev/null
      docker ps -a --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
        | grep -E '\bleech\b'
    } | sort -u | grep -v "^$"
  )

  if [[ -n "$session_rows" ]]; then
    while IFS=$'\t' read -r name status ports; do
      [[ -z "$name" ]] && continue
      local icon uptime=""
      if echo "$status" | grep -qi "^up"; then
        icon="${GREEN}●${RESET}"
        uptime=$(echo "$status" | sed -E 's/Up //i; s/ \(.*\)//; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/')
      else
        icon="${RED}○${RESET}"
      fi

      # imagem
      local image
      image=$(docker inspect --format '{{.Config.Image}}' "$name" 2>/dev/null || echo "?")

      # verifica se JOURNAL_GID está nos groups do container
      local gid_status=""
      if [[ -n "$jgid" ]]; then
        local container_groups
        container_groups=$(docker inspect --format '{{join .HostConfig.GroupAdd ","}}' "$name" 2>/dev/null || true)
        if echo "$container_groups" | grep -qw "$jgid"; then
          gid_status="  ${GREEN}journal✓${RESET}"
        else
          gid_status="  ${RED}journal✗ (recrie com zion new)${RESET}"
        fi
      fi

      echo -e "  ${icon} ${WHITE}${name}${RESET}  ${ORANGE}${uptime}${RESET}  ${DIM}${image}${RESET}${gid_status}"
    done <<< "$session_rows"
  else
    echo -e "  ${RED}○${RESET} ${DIM}nenhum container de sessão${RESET}"
  fi
  echo ""

  # ── Dockerized services ──────────────────────────────────────────────────
  source "${ZION_ROOT:-$HOME/nixos/zion}/cli/src/lib/docker_status_impl.sh" 2>/dev/null || true
  if declare -f _zion_dk_status >/dev/null 2>&1; then
    _zion_dk_status
  else
    echo -e "${BOLD}${CYAN}  Dockerized${RESET}"
    local dk_rows
    dk_rows=$(docker ps -a --format "  {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
      | grep -E 'zion-dk|zion-reverseproxy' || true)
    if [[ -n "$dk_rows" ]]; then
      echo "$dk_rows" | column -t -s $'\t'
    else
      echo -e "  ${DIM}nenhum${RESET}"
    fi
    echo ""
  fi
fi

# ── Cota ──────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}  Cota${RESET}"
local usage_script="${ZION_ROOT:-$HOME/nixos/zion}/scripts/claude-ai-usage.sh"
[ -x "$usage_script" ] && "$usage_script" 2>/dev/null | tail -2 | sed 's/^/  /' || echo -e "  ${DIM}sem dados${RESET}"
echo ""
