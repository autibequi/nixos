# leech sentinel — mantém o computador acordado para acesso remoto
# Usa systemd-inhibit para bloquear sleep/idle/lid-close

SENTINEL_PID_FILE="/tmp/leech-sentinel.pid"
SENTINEL_LOG="/tmp/leech-sentinel.log"

GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

_sentinel_pid() {
  [[ -f "$SENTINEL_PID_FILE" ]] || return 1
  local pid
  pid=$(cat "$SENTINEL_PID_FILE" 2>/dev/null) || return 1
  kill -0 "$pid" 2>/dev/null && echo "$pid"
}

_battery_status() {
  local ac_online bat_pct
  ac_online=$(cat /sys/class/power_supply/AC/online 2>/dev/null \
           || cat /sys/class/power_supply/AC0/online 2>/dev/null \
           || echo "?")
  bat_pct=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "?")

  if [[ "$ac_online" == "1" ]]; then
    echo -e "${GREEN}AC${RESET} ${DIM}${bat_pct}%${RESET}"
  elif [[ "$ac_online" == "0" ]]; then
    echo -e "${YELLOW}bateria${RESET} ${DIM}${bat_pct}%${RESET}"
  else
    echo -e "${DIM}fonte desconhecida${RESET}"
  fi
}

action="${args['action']:-start}"

case "$action" in
  start)
    if pid=$(_sentinel_pid); then
      echo -e "${GREEN}● sentinel ja ativo${RESET}  pid=${pid}"
      echo -e "  fonte: $(_battery_status)"
      exit 0
    fi

    if ! command -v systemd-inhibit >/dev/null 2>&1; then
      echo -e "${RED}✗ systemd-inhibit nao encontrado${RESET}" >&2
      exit 1
    fi

    echo -e "${CYAN}→ ativando sentinel${RESET}  (bloqueia sleep + idle + lid-close)"
    echo -e "  fonte: $(_battery_status)"

    systemd-inhibit \
      --what=sleep:idle:handle-lid-switch \
      --who="Leech Sentinel" \
      --why="Remote access active" \
      --mode=block \
      sleep infinity \
      >> "$SENTINEL_LOG" 2>&1 &

    local inh_pid=$!
    echo "$inh_pid" > "$SENTINEL_PID_FILE"

    sleep 0.5
    if kill -0 "$inh_pid" 2>/dev/null; then
      echo -e "${GREEN}● sentinel ativo${RESET}  pid=${inh_pid}"
      echo -e "${DIM}  pare com:     leech sentinel stop${RESET}"
      echo -e "${DIM}  desligue com: leech sentinel poweroff${RESET}"
    else
      rm -f "$SENTINEL_PID_FILE"
      echo -e "${RED}✗ sentinel falhou ao iniciar${RESET}" >&2
      echo -e "${DIM}  log: ${SENTINEL_LOG}${RESET}" >&2
      exit 1
    fi
    ;;

  stop)
    if ! pid=$(_sentinel_pid); then
      echo -e "${DIM}sentinel nao esta ativo${RESET}"
      exit 0
    fi
    kill "$pid" 2>/dev/null
    rm -f "$SENTINEL_PID_FILE"
    echo -e "${YELLOW}○ sentinel desativado${RESET}  pid=${pid}"
    echo -e "${DIM}  computador pode dormir novamente${RESET}"
    ;;

  status)
    if pid=$(_sentinel_pid); then
      local uptime_s
      uptime_s=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ' || echo "?")
      local uptime_fmt="?"
      if [[ "$uptime_s" =~ ^[0-9]+$ ]]; then
        local h=$(( uptime_s / 3600 ))
        local m=$(( (uptime_s % 3600) / 60 ))
        local s=$(( uptime_s % 60 ))
        [[ $h -gt 0 ]] && uptime_fmt="${h}h${m}m" || uptime_fmt="${m}m${s}s"
      fi
      echo -e "${GREEN}● sentinel ativo${RESET}  pid=${pid}  uptime=${uptime_fmt}"
      echo -e "  fonte: $(_battery_status)"
      if command -v systemd-inhibit >/dev/null 2>&1; then
        echo -e "${DIM}"
        systemd-inhibit --list 2>/dev/null | grep -i "Leech" | sed 's/^/  /' || true
        echo -ne "${RESET}"
      fi
    else
      echo -e "${RED}○ sentinel inativo${RESET}  (use: leech sentinel start)"
      echo -e "  fonte: $(_battery_status)"
    fi
    ;;

  poweroff)
    echo -e "${BOLD}${RED}desligando o computador...${RESET}"
    if pid=$(_sentinel_pid); then
      kill "$pid" 2>/dev/null
      rm -f "$SENTINEL_PID_FILE"
    fi
    sleep 1
    systemctl poweroff
    ;;

  *)
    echo "leech sentinel: acao invalida '${action}'" >&2
    echo "  uso: leech sentinel [start|stop|status|poweroff]" >&2
    exit 1
    ;;
esac
