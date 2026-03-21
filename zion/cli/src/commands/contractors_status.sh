# Mostra os últimos 20 jobs de contractors com start e duração
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local logbase="$obsidian/vault/.ephemeral/cron-logs"

if [ ! -d "$logbase" ]; then
  for try in "/workspace/obsidian/vault/.ephemeral/cron-logs" "$HOME/obsidian/vault/.ephemeral/cron-logs"; do
    [ -d "$try" ] && logbase="$try" && break
  done
fi

if [ ! -d "$logbase" ]; then
  echo "Log dir nao encontrado: $logbase"
  exit 1
fi

mapfile -t logs < <(find "$logbase" -name "*.log" ! -name "daemon.log" -printf "%f %p\n" 2>/dev/null \
  | sort -rn | head -20 | awk '{print $2}')

if [ ${#logs[@]} -eq 0 ]; then
  echo "Nenhum log encontrado."
  exit 0
fi

local G=$'\033[32m' Y=$'\033[33m' M=$'\033[35m' R=$'\033[0m' B=$'\033[1m' D=$'\033[2m' C=$'\033[36m'
local now_epoch
now_epoch=$(date +%s)

# Diretório de cards para lookup de model
local taskdir="${TASK_DIR:-/workspace/obsidian/tasks}"

# Função: lê model do frontmatter do card do contractor
lookup_model() {
  local name="$1"
  local card
  card=$(grep -rl "^contractor: ${name}$" "$taskdir/TODO" "$taskdir/DOING" 2>/dev/null | head -1)
  [[ -z "$card" ]] && echo "-" && return
  awk '/^model:/{print $2; exit}' "$card"
}

printf "${B}%-14s %-8s %-16s %-12s %s${R}\n" "CONTRACTOR" "MODEL" "INÍCIO" "STATUS" "IDADE"
printf "${D}%-14s %-8s %-16s %-12s %s${R}\n" "--------------" "--------" "----------------" "------------" "----------"

for logfile in "${logs[@]}"; do
  contractor=$(basename "$(dirname "$logfile")")
  filename=$(basename "$logfile" .log)
  date_part="${filename%%_*}"
  time_part="${filename##*_}"
  time_fmt="${time_part//-/:}"
  ts="${date_part} ${time_fmt}"

  model=$(lookup_model "$contractor")

  # usar stat mtime do arquivo como fallback mais confiável que parse de filename
  start_epoch=$(date -d "${date_part} ${time_fmt}:00" +%s 2>/dev/null || echo "0")

  # Idade relativa (mínimo minutos; negativo = relógio skew, mostrar "agora")
  age="-"
  if [[ "$start_epoch" -gt 0 ]]; then
    diff=$(( now_epoch - start_epoch ))
    if   (( diff <= 90 ));   then age="agora"
    elif (( diff < 3600 ));  then age="$(( diff / 60 ))min atrás"
    elif (( diff < 86400 )); then age="$(( diff / 3600 ))h atrás"
    else age="$(( diff / 86400 ))d atrás"
    fi
  fi

  status_plain="?"
  status_color="${D}?${R}"

  if grep -q "Reached max turns" "$logfile" 2>/dev/null; then
    turns=$(grep -oE "max turns \([0-9]+\)" "$logfile" | grep -oE "[0-9]+" | tail -1)
    status_plain="max(${turns}t)"
    status_color="${Y}${status_plain}${R}"
  elif grep -q "rescheduled\|reschedule" "$logfile" 2>/dev/null; then
    status_plain="resched"
    status_color="${Y}${status_plain}${R}"
  elif grep -q "QUOTA_HOLD" "$logfile" 2>/dev/null; then
    status_plain="quota"
    status_color="${M}${status_plain}${R}"
  elif [[ $(wc -c < "$logfile") -gt 0 ]]; then
    status_plain="done"
    status_color="${G}${status_plain}${R}"
  fi

  pad=$(( 12 - ${#status_plain} ))
  [[ $pad -lt 0 ]] && pad=0
  spaces=$(printf '%*s' "$pad" '')
  printf "%-14s ${D}%-8s${R}${D}%-16s${R} %s%s ${C}%s${R}\n" "$contractor" "$model" "$ts" "${status_color}" "$spaces" "$age"
done
printf "${D}  done=terminou  max(Nt)=bateu limite de turns  resched=reagendado  quota=pausado por cota${R}\n"
