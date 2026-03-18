# Remove sessoes Zion paradas/exited e containers orfaos.
zion_load_config

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'

force="${args[--force]:-}"

# 1. Sessoes exited (zion-* excluindo zion-dk-*)
exited=$(docker ps -a --filter "name=zion-" --filter "status=exited" \
  --format "{{.ID}}\t{{.Names}}\t{{.Status}}" 2>/dev/null \
  | grep -v "zion-dk-" || true)

# 2. Sessoes created mas nunca rodaram
created=$(docker ps -a --filter "name=zion-" --filter "status=created" \
  --format "{{.ID}}\t{{.Names}}\t{{.Status}}" 2>/dev/null \
  | grep -v "zion-dk-" || true)

# 3. Sessoes dead
dead=$(docker ps -a --filter "name=zion-" --filter "status=dead" \
  --format "{{.ID}}\t{{.Names}}\t{{.Status}}" 2>/dev/null \
  | grep -v "zion-dk-" || true)

all_stale=""
[[ -n "$exited" ]] && all_stale+="$exited"$'\n'
[[ -n "$created" ]] && all_stale+="$created"$'\n'
[[ -n "$dead" ]] && all_stale+="$dead"$'\n'
# Remove blank lines
all_stale=$(echo "$all_stale" | sed '/^$/d')

if [[ -z "$all_stale" ]]; then
  echo -e "${GREEN}●${RESET} Nenhum container parado para limpar."
  exit 0
fi

count=$(echo "$all_stale" | wc -l)
echo -e "${BOLD}${CYAN}Sessoes paradas:${RESET} ${count}\n"

while IFS=$'\t' read -r id name status; do
  [[ -z "$id" ]] && continue
  short="${name#zion-}"
  echo -e "  ${RED}○${RESET} ${short}  ${DIM}${status}${RESET}"
done <<< "$all_stale"

echo ""

if [[ -z "$force" ]]; then
  read -rp "Remover ${count} container(s)? [y/N] " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Cancelado."; exit 0; }
fi

# Remove
removed=0
while IFS=$'\t' read -r id name status; do
  [[ -z "$id" ]] && continue
  docker rm -f "$id" >/dev/null 2>&1 && removed=$((removed + 1))
done <<< "$all_stale"

echo -e "\n${GREEN}●${RESET} ${removed}/${count} containers removidos."

# Prune dangling networks from compose runs
docker network prune -f >/dev/null 2>&1 || true
