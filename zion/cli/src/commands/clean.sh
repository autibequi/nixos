# Remove sessoes Zion orfas: exited, dead, ou running com apenas sleep infinity.
zion_load_config

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'

force="${args[--force]:-}"

# Collect all zion session containers (exclude zion-dk-* = docker services)
all_sessions=$(docker ps -a --filter "name=zion-" \
  --format "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.State}}" 2>/dev/null \
  | grep -v "zion-dk-" || true)

[[ -z "$all_sessions" ]] && { echo -e "${GREEN}●${RESET} Nenhuma sessao encontrada."; exit 0; }

stale_ids=()
stale_lines=()

while IFS=$'\t' read -r id name status state; do
  [[ -z "$id" ]] && continue

  if [[ "$state" != "running" ]]; then
    # Exited, dead, created — sempre stale
    stale_ids+=("$id")
    stale_lines+=("${RED}○${RESET} ${name#zion-}  ${DIM}${status}${RESET}")
    continue
  fi

  # Running: check if it's an orphan (only sleep/bash, no agent process)
  # A live session has claude, cursor, or opencode running inside
  procs=$(docker exec "$id" ps -eo comm 2>/dev/null | grep -cE '(claude|cursor|opencode)' || true)
  procs="${procs:-0}"
  if [[ "$procs" -eq 0 ]]; then
    stale_ids+=("$id")
    stale_lines+=("${YELLOW}◐${RESET} ${name#zion-}  ${DIM}${status} (orphan — no agent)${RESET}")
  fi
done <<< "$all_sessions"

if [[ "${#stale_ids[@]}" -eq 0 ]]; then
  echo -e "${GREEN}●${RESET} Nenhum container orfao para limpar."
  exit 0
fi

count="${#stale_ids[@]}"
echo -e "${BOLD}${CYAN}Sessoes para remover:${RESET} ${count}\n"

for line in "${stale_lines[@]}"; do
  echo -e "  $line"
done

echo ""

if [[ -z "$force" ]]; then
  read -rp "Remover ${count} container(s)? [y/N] " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelado."; exit 0; }
fi

removed=0
for id in "${stale_ids[@]}"; do
  docker rm -f "$id" >/dev/null 2>&1 && removed=$((removed + 1))
done

echo -e "\n${GREEN}●${RESET} ${removed}/${count} containers removidos."

# Prune dangling networks
docker network prune -f >/dev/null 2>&1 || true
