#!/usr/bin/env bash
# zion-agent-launch.sh — loading com timing aleatorio; troca pro claude assim que bootstrap termina
# Uso: bash zion-agent-launch.sh [claude args...]

G='\033[32m'; C='\033[36m'; Y='\033[33m'; D='\033[2m'; R='\033[0m'

_ok()   { printf "  ${G}[ OK ]${R}  ${D}%s${R}\n" "$1"; }
_info() { printf "  ${C}[INFO]${R}  ${D}%s${R}\n" "$1"; }
_wait() { printf "  ${Y}[ .. ]${R}  ${D}%s${R}\n" "$1"; }

# Pausa aleatoria em centisegundos; retorna 1 se bootstrap terminou durante a espera
_rnd() {
  local steps=$(( RANDOM % $2 + $1 )) i=0
  while [[ $i -lt $steps ]]; do
    sleep 0.01
    kill -0 "$BOOT_PID" 2>/dev/null || return 1
    i=$(( i + 1 ))
  done
  return 0
}

# Imprime linha e pausa; retorna 1 se bootstrap terminou (sinal para parar loop)
_line() {
  local type="$1" msg="$2" min="$3" range="$4"
  kill -0 "$BOOT_PID" 2>/dev/null || return 1
  case "$type" in
    ok)   _ok   "$msg" ;;
    info) _info "$msg" ;;
    wait) _wait "$msg" ;;
  esac
  _rnd "$min" "$range"
}

printf '\033[2J\033[H\033[?25l\n'

# Bootstrap em background — todos os efeitos sao filesystem
bash -c '. /workspace/self/scripts/bootstrap.sh' >/tmp/zion-boot.log 2>&1 &
BOOT_PID=$!

# Mensagens — cada uma checa se bootstrap terminou; se sim, para imediatamente
_line ok   "container filesystem mounted"        20 48  &&
_line ok   "nix daemon started"                  28 68  &&
_line info "loading zion bootstrap..."           40 94  &&
_line ok   "workspace volumes attached"          20 54  &&
_line ok   "docker socket connected"             16 40  &&
_line info "scanning environment variables..."   30 68  &&
_line ok   "ANTHROPIC_API_KEY found"             16 40  &&
_line ok   "GH_TOKEN found"                      14 34  &&
_line info "locating obsidian vault..."          34 74  &&
_line ok   "obsidian vault connected"            24 54  &&
_line info "loading agent memory..."             48 100 &&
_line ok   "memory loaded — 11 agents online"   24 48  &&
_line ok   "hooks registered"                    28 54  &&
_line info "syncing credentials with host..."    34 68  &&
_line ok   "credentials synced"                  16 40  &&
_line ok   "claude tools registered"             24 48  &&
_line info "checking mcp servers..."             34 74  &&
_line ok   "mcp: grafana connected"              16 40  &&
_line ok   "mcp: atlassian connected"            16 40  &&
_line wait "bark bark protocol initialized"      40 80  &&
_line info "warming up agent context..."         48 94  &&
_line wait "acordando o agente..."               50 116
# Se chegou aqui, bootstrap ainda nao terminou — espera sem mais texto
wait "$BOOT_PID" 2>/dev/null || true

_ok "agente pronto"
sleep 0.15

printf '\033[?25h\033[2J\033[H'
cd /workspace/mnt
exec /home/claude/.nix-profile/bin/claude "$@"
