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

mapfile -t logs < <(find "$logbase" -name "*.log" ! -name "daemon.log" -printf "%T@ %p\n" 2>/dev/null \
  | sort -rn | head -20 | awk '{print $2}')

if [ ${#logs[@]} -eq 0 ]; then
  echo "Nenhum log encontrado."
  exit 0
fi

local G=$'\033[32m' Y=$'\033[33m' M=$'\033[35m' R=$'\033[0m' B=$'\033[1m' D=$'\033[2m'

printf "${B}%-18s %-14s %-8s %-10s${R}\n" "DATA/HORA" "CONTRACTOR" "STATUS" "DURAÇÃO"
printf "${D}%-18s %-14s %-8s %-10s${R}\n" "------------------" "--------------" "--------" "----------"

for logfile in "${logs[@]}"; do
  contractor=$(basename "$(dirname "$logfile")")
  filename=$(basename "$logfile" .log)
  date_part="${filename%%_*}"
  time_part="${filename##*_}"
  time_fmt="${time_part//-/:}"
  ts="${date_part} ${time_fmt}"

  start_epoch=$(date -d "${date_part} ${time_fmt}:00" +%s 2>/dev/null || echo "0")
  end_epoch=$(stat -c %Y "$logfile" 2>/dev/null || echo "0")
  duration="-"
  if [[ "$start_epoch" -gt 0 && "$end_epoch" -gt "$start_epoch" ]]; then
    secs=$(( end_epoch - start_epoch ))
    duration="$(( secs / 60 ))m$(( secs % 60 ))s"
  fi

  status_plain="?"
  status_color="${D}?${R}"

  if grep -q "Reached max turns" "$logfile" 2>/dev/null; then
    turns=$(grep -oE "max turns \([0-9]+\)" "$logfile" | grep -oE "[0-9]+" | tail -1)
    status_plain="done(${turns}t)"
    status_color="${G}${status_plain}${R}"
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

  pad=$(( 8 - ${#status_plain} ))
  [[ $pad -lt 0 ]] && pad=0
  spaces=$(printf '%*s' "$pad" '')
  printf "%-18s %-14s %s%s %-10s\n" "$ts" "$contractor" "${status_color}" "$spaces" "$duration"
done
