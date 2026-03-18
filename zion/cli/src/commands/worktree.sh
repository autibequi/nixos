# Lista worktrees dos servicos Docker e permite escolher worktree + comando interativamente.
zion_load_config

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
CYAN='\033[36m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
WHITE='\033[37m'

filter_service="${args[service]:-}"

# ── 1. Coletar worktrees de todos os servicos ───────────────────────────────
declare -a wt_entries=()   # "service|worktree_name|path|branch"
declare -a wt_display=()   # display string para selecao

services="monolito bo-container front-student"
[[ -n "$filter_service" ]] && services="$filter_service"

for svc in $services; do
  dir=$(zion_docker_service_dir "$svc" 2>/dev/null)
  [[ ! -d "$dir" ]] && continue

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    wt_path="${line%% *}"
    rest="${line#* }"
    # Extrair hash e branch
    branch=$(echo "$rest" | grep -oP '\[.*?\]' | tr -d '[]')
    wt_name=$(basename "$wt_path")

    wt_entries+=("${svc}|${wt_name}|${wt_path}|${branch}")
    wt_display+=("$(printf "%-16s %-24s %s" "$svc" "$wt_name" "[$branch]")")
  done < <(git -C "$dir" worktree list 2>/dev/null)
done

if [[ ${#wt_entries[@]} -eq 0 ]]; then
  echo "Nenhum worktree encontrado."
  [[ -n "$filter_service" ]] && echo "Servico: $filter_service"
  echo "Servicos verificados: $services"
  exit 0
fi

# ── 2. Listar worktrees ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${MAGENTA}  Worktrees${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}"
echo ""

current_svc=""
for i in "${!wt_entries[@]}"; do
  IFS='|' read -r svc wt_name wt_path branch <<< "${wt_entries[$i]}"
  if [[ "$svc" != "$current_svc" ]]; then
    [[ -n "$current_svc" ]] && echo ""
    echo -e "  ${BOLD}${CYAN}$svc${RESET}"
    current_svc="$svc"
  fi
  # Marcar main/principal
  local_dir=$(zion_docker_service_dir "$svc" 2>/dev/null)
  if [[ "$wt_path" == "$local_dir" ]]; then
    echo -e "    ${GREEN}$((i+1)))${RESET} ${WHITE}${wt_name}${RESET}  ${DIM}${branch}${RESET}  ${YELLOW}(main)${RESET}"
  else
    echo -e "    ${GREEN}$((i+1)))${RESET} ${WHITE}${wt_name}${RESET}  ${DIM}${branch}${RESET}"
  fi
done
echo ""

# ── 3. Escolher worktree ────────────────────────────────────────────────────
echo -en "${BOLD}Worktree [1-${#wt_entries[@]}]: ${RESET}"
read -r wt_choice

# Validar
if [[ -z "$wt_choice" || ! "$wt_choice" =~ ^[0-9]+$ || "$wt_choice" -lt 1 || "$wt_choice" -gt ${#wt_entries[@]} ]]; then
  echo "Cancelado."
  exit 0
fi

idx=$((wt_choice - 1))
IFS='|' read -r chosen_svc chosen_wt chosen_path chosen_branch <<< "${wt_entries[$idx]}"

# Se escolheu o main dir, nao precisa de --worktree
main_dir=$(zion_docker_service_dir "$chosen_svc" 2>/dev/null)
wt_flag=""
if [[ "$chosen_path" != "$main_dir" ]]; then
  wt_flag=" --worktree=$chosen_wt"
fi

echo ""
echo -e "  Selecionado: ${BOLD}${chosen_svc}${RESET} → ${CYAN}${chosen_wt}${RESET} ${DIM}[${chosen_branch}]${RESET}"
echo ""

# ── 4. Escolher comando ─────────────────────────────────────────────────────
cmds=("run" "shell" "logs" "stop" "restart" "install" "flush" "status")
echo -e "${BOLD}Comando:${RESET}"
for i in "${!cmds[@]}"; do
  echo -e "  ${GREEN}$((i+1)))${RESET} ${cmds[$i]}"
done
echo ""
echo -en "${BOLD}Comando [1-${#cmds[@]}]: ${RESET}"
read -r cmd_choice

if [[ -z "$cmd_choice" || ! "$cmd_choice" =~ ^[0-9]+$ || "$cmd_choice" -lt 1 || "$cmd_choice" -gt ${#cmds[@]} ]]; then
  echo "Cancelado."
  exit 0
fi

chosen_cmd="${cmds[$((cmd_choice - 1))]}"

# ── 5. Montar comando e deixar usuario confirmar ────────────────────────────
final_cmd="zion docker ${chosen_cmd} ${chosen_svc}${wt_flag}"

echo ""
echo -e "${DIM}Edite o comando se necessario e pressione Enter para executar:${RESET}"
read -e -r -p "> " -i "$final_cmd" edited_cmd

if [[ -z "$edited_cmd" ]]; then
  echo "Cancelado."
  exit 0
fi

# ── 6. Executar ──────────────────────────────────────────────────────────────
echo ""
eval "$edited_cmd"
