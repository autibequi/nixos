#!/usr/bin/env bash
# leech-agent-launch.sh — loading screen com timing aleatorio + bootstrap real em paralelo
# Uso: bash leech-agent-launch.sh [claude args...]

G='\033[32m'; C='\033[36m'; Y='\033[33m'; D='\033[2m'; R='\033[0m'

_ok()   { printf "  ${G}[ OK ]${R}  ${D}%s${R}\n" "$1"; }
_info() { printf "  ${C}[INFO]${R}  ${D}%s${R}\n" "$1"; }
_wait() { printf "  ${Y}[ .. ]${R}  ${D}%s${R}\n" "$1"; }

# Bootstrap em background — todos os efeitos sao filesystem
bash -c '. /workspace/self/scripts/bootstrap.sh' >/tmp/leech-boot.log 2>&1 &
BOOT_PID=$!

# Splash desativado via LEECH_SPLASH=0 (setar em ~/.leech ou passar --no-splash)
if [[ "${LEECH_SPLASH:-1}" == "0" ]]; then
  printf '\033[2J\033[H'
  _wait "loading agent..."
  wait "$BOOT_PID" 2>/dev/null || true
  printf '\033[2J\033[H'
  cd /workspace/mnt
  exec /home/claude/.nix-profile/bin/claude --enable-auto-mode "$@"
fi

printf '\033[2J\033[H\033[?25l\n'

LINES=(
  "ok|container filesystem mounted|20|48"
  "ok|nix daemon started|28|68"
  "info|loading leech bootstrap...|40|94"
  "ok|workspace volumes attached|20|54"
  "ok|docker socket connected|16|40"
  "info|scanning environment variables...|30|68"
  "ok|ANTHROPIC_API_KEY found|16|40"
  "ok|GH_TOKEN found|14|34"
  "info|locating obsidian vault...|34|74"
  "ok|obsidian vault connected|24|54"
  "info|loading agent memory...|48|100"
  "ok|memory loaded — 11 agents online|24|48"
  "ok|hooks registered|28|54"
  "info|syncing credentials with host...|34|68"
  "ok|credentials synced|16|40"
  "ok|claude tools registered|24|48"
  "info|checking mcp servers...|34|74"
  "ok|mcp: grafana connected|16|40"
  "ok|mcp: atlassian connected|16|40"
  "wait|bark bark protocol initialized|40|80"
  "info|warming up agent context...|48|94"
  "wait|acordando o agente...|50|116"
)

for entry in "${LINES[@]}"; do
  IFS='|' read -r type msg min range <<< "$entry"

  # Para imediatamente se bootstrap terminou
  kill -0 "$BOOT_PID" 2>/dev/null || break

  case "$type" in
    ok)   _ok   "$msg" ;;
    info) _info "$msg" ;;
    wait) _wait "$msg" ;;
  esac

  # Pausa aleatoria com checagem a cada 0.03s
  steps=$(( RANDOM % range + min ))
  i=0
  while [[ $i -lt $steps ]]; do
    sleep 0.06
    kill -0 "$BOOT_PID" 2>/dev/null || break 2
    i=$(( i + 1 ))
  done
done

# Se bootstrap ainda nao terminou, espera em silencio
wait "$BOOT_PID" 2>/dev/null || true

_ok "agente pronto"
sleep 0.2

printf '\033[?25h\033[2J\033[H'
cd /workspace/mnt
exec /home/claude/.nix-profile/bin/claude --enable-auto-mode "$@"
