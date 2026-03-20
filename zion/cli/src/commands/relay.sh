# zion relay — Inicia Chrome no host com CDP para o agent conectar
zion_load_config

RELAY_PORT=9222
RELAY_PROFILE="/tmp/zion-relay"
RELAY_URL="http://localhost:${RELAY_PORT}"

GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

_relay_running() {
  curl -sf "${RELAY_URL}/json/version" >/dev/null 2>&1
}

_relay_pid() {
  pgrep -f "remote-debugging-port=${RELAY_PORT}" | head -1
}

action="${args['action']:-start}"

case "$action" in
  start)
    if _relay_running; then
      pid=$(_relay_pid)
      echo -e "${GREEN}● relay ja rodando${RESET}  pid=${pid}  port=${RELAY_PORT}"
      echo -e "${DIM}  Agent conecta via CDP em localhost:${RELAY_PORT}${RESET}"
      exit 0
    fi

    # Detecta browser disponivel
    browser=""
    for b in google-chrome-stable google-chrome chromium chromium-browser; do
      if command -v "$b" >/dev/null 2>&1; then
        browser="$b"
        break
      fi
    done

    if [[ -z "$browser" ]]; then
      echo -e "${RED}✗ Nenhum Chrome/Chromium encontrado no PATH${RESET}" >&2
      echo -e "${DIM}  Instale com: nix-env -iA nixpkgs.chromium${RESET}" >&2
      exit 1
    fi

    echo -e "${CYAN}→ Iniciando relay${RESET}  browser=${browser}  port=${RELAY_PORT}"
    echo -e "${DIM}  perfil isolado: ${RELAY_PROFILE}${RESET}"

    "$browser" \
      --remote-debugging-port="${RELAY_PORT}" \
      --user-data-dir="${RELAY_PROFILE}" \
      --no-first-run \
      --no-default-browser-check \
      about:blank \
      >/dev/null 2>&1 &

    # Aguarda CDP subir (max 5s)
    for i in $(seq 1 10); do
      sleep 0.5
      if _relay_running; then
        pid=$(_relay_pid)
        echo -e "${GREEN}● relay pronto${RESET}  pid=${pid}  port=${RELAY_PORT}"
        echo -e "${DIM}  Agent conecta automaticamente via CDP${RESET}"
        exit 0
      fi
    done

    echo -e "${RED}✗ Chrome iniciou mas CDP nao respondeu em 5s${RESET}" >&2
    exit 1
    ;;

  stop)
    pid=$(_relay_pid)
    if [[ -z "$pid" ]]; then
      echo -e "${DIM}relay nao esta rodando${RESET}"
      exit 0
    fi
    kill "$pid" 2>/dev/null
    echo -e "${YELLOW}○ relay encerrado${RESET}  pid=${pid}"
    ;;

  status)
    if _relay_running; then
      pid=$(_relay_pid)
      tabs=$(curl -sf "${RELAY_URL}/json" 2>/dev/null | python3 -c "import sys,json; tabs=json.load(sys.stdin); print(len([t for t in tabs if t.get('type')=='page']))" 2>/dev/null || echo "?")
      echo -e "${GREEN}● relay ativo${RESET}  pid=${pid}  port=${RELAY_PORT}  abas=${tabs}"
    else
      echo -e "${RED}○ relay inativo${RESET}  (use: zion relay start)"
    fi
    ;;

  *)
    echo "zion relay: acao invalida '${action}'" >&2
    echo "  uso: zion relay [start|stop|status]" >&2
    exit 1
    ;;
esac
