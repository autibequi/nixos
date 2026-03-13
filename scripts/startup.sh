#!/usr/bin/env bash
# Claudinho startup — mostra estado do workspace rapidamente
set -euo pipefail

# Cores
R='\033[0m' B='\033[1m' DIM='\033[2m'
CYAN='\033[36m' GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m'

WS="/workspace"
KANBAN="$WS/vault/kanban.md"
SCHEDULED="$WS/vault/scheduled.md"
TODAY=$(date +%Y-%m-%d)
now=$(date +%s)

# --- Helpers ---
fmt_age() {
  local s="$1" h=$(( $1 / 3600 )) m=$(( ($1 % 3600) / 60 ))
  [[ $h -gt 0 ]] && echo "${h}h${m}m" || echo "${m}m"
}

find_latest_log() {
  local tier="$1" best="" best_mod=0
  [[ -f "$WS/.ephemeral/logs/worker-${tier}.log" ]] && {
    best="$WS/.ephemeral/logs/worker-${tier}.log"
    best_mod=$(stat -c %Y "$best" 2>/dev/null || echo 0)
  }
  local legacy; legacy=$(ls -t "$WS"/logs/*.log 2>/dev/null | head -1)
  if [[ -n "$legacy" ]]; then
    local lmod; lmod=$(stat -c %Y "$legacy" 2>/dev/null || echo 0)
    [[ "$lmod" -gt "$best_mod" ]] && { best="$legacy"; best_mod="$lmod"; }
  fi
  echo "$best_mod:$best"
}

# --- Trocadilho ---
PUNS=("Claud-íssimo" "Claud-estino" "Claud-ificado" "Claud-aluz" "Claud-inâmica" "Claud-etonante" "Claud-eroso" "Claud-emaravilha")
echo
echo
echo -e "${B}${CYAN}${PUNS[$((RANDOM % ${#PUNS[@]}))]}${R} presente! ⚡"

# --- Workers (systemd oneshot + timer → detect via log age) ---
worker_parts=()
for tier in fast heavy; do
  IFS=: read -r last_mod last_log <<< "$(find_latest_log "$tier")"

  if [[ -z "$last_log" ]]; then
    worker_parts+=("${RED}🔴 ${tier}${R} ${DIM}--${R}")
  else
    age=$(( now - last_mod ))
    # Thresholds: fast timer=10min (max=900s), heavy timer=1h (max=4200s)
    if [[ "$tier" == "fast" ]]; then max=900; else max=4200; fi

    if [[ $age -le 120 ]]; then
      # Log touched in last 2min → worker actively running
      worker_parts+=("${GREEN}🟢 ${tier}${R} ${DIM}running${R}")
    elif [[ $age -le $max ]]; then
      # Within expected timer interval → healthy
      worker_parts+=("${GREEN}🟢 ${tier}${R} ${DIM}$(fmt_age $age)${R}")
    else
      # Older than expected → timer may be stuck
      worker_parts+=("${YELLOW}🟡 ${tier}${R} ${DIM}$(fmt_age $age)${R}")
    fi
  fi
done
echo -e "${B}Workers:${R} ${worker_parts[0]}  ${worker_parts[1]}"

# --- Git + Modo (mesma linha) ---
ws_branch=$(git -C "$WS" branch --show-current 2>/dev/null || echo "?")
ws_dirty=$(git -C "$WS" status --porcelain 2>/dev/null | head -1)
ws_ahead=$(git -C "$WS" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
ws_behind=$(git -C "$WS" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
git_str="[${ws_branch}]"
[[ -n "$ws_dirty" ]] && git_str+=" ${YELLOW}dirty${R}" || git_str+=" ${GREEN}clean${R}"
[[ "$ws_ahead" -gt 0 ]] && git_str+=" ${GREEN}↑${ws_ahead}${R}"
[[ "$ws_behind" -gt 0 ]] && git_str+=" ${RED}↓${ws_behind}${R}"

MODE_FILE="$WS/projetos/CLAUDE.md"
if [[ -f "$MODE_FILE" ]] && grep -q 'FÉRIAS \[OFF\]' "$MODE_FILE" 2>/dev/null; then
  ferias_str="${RED}OFF${R}"
else
  ferias_str="${GREEN}ON${R}"
fi
echo -e "${B}Git:${R} ${git_str}  ${B}Ferias:${R} ${ferias_str}"

# --- Inbox (coluna do kanban) ---
if [[ -f "$KANBAN" ]]; then
  inbox_count=0; in_inbox=0
  while IFS= read -r line; do
    [[ "$line" == "## Inbox" ]] && { in_inbox=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_inbox" == "1" ]] && break
    [[ "$in_inbox" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && inbox_count=$((inbox_count + 1))
  done < "$KANBAN"
  [[ "$inbox_count" -gt 0 ]] && echo -e "${B}Inbox:${R} ${YELLOW}${inbox_count} pendente(s)${R}"
fi

# --- Kanban (lista unificada) ---
if [[ -f "$KANBAN" ]]; then
  items=()

  # Em Andamento → [/]
  in_col=0
  while IFS= read -r line; do
    [[ "$line" == "## Em Andamento" ]] && { in_col=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]] && break
    if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
      after="${line#*\*\*}"; name="${after%%\*\**}"
      desc=""; if [[ "$line" == *" — "* ]]; then
        raw="${line##* — }"; [[ ${#raw} -gt 30 ]] && raw="${raw:0:27}..."
        desc=" ${raw}"
      fi
      items+=("${YELLOW}[/] ${name}${DIM}${desc}${R}")
    fi
  done < "$KANBAN"

  # Backlog → [ ]
  in_col=0
  while IFS= read -r line; do
    [[ "$line" == "## Backlog" ]] && { in_col=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]] && break
    if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
      after="${line#*\*\*}"; name="${after%%\*\**}"
      desc=""; if [[ "$line" == *" — "* ]]; then
        raw="${line##* — }"; [[ ${#raw} -gt 30 ]] && raw="${raw:0:27}..."
        desc=" ${raw}"
      fi
      items+=("${DIM}[ ] ${name}${desc}${R}")
    fi
  done < "$KANBAN"

  # Concluído (hoje) → [x]
  in_col=0
  while IFS= read -r line; do
    [[ "$line" == "## Concluido" ]] && { in_col=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]] && break
    if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"$TODAY"* ]]; then
      after="${line#*\*\*}"; name="${after%%\*\**}"
      items+=("${GREEN}[x] ${name}${R}")
    fi
  done < "$KANBAN"

  # Rodapé info — recorrentes vêm do scheduled.md
  rec=0; in_rec=0
  if [[ -f "$SCHEDULED" ]]; then
    while IFS= read -r line; do
      [[ "$line" == "## Recorrentes" ]] && { in_rec=1; continue; }
      [[ "$line" =~ ^##\  ]] && [[ "$in_rec" == "1" ]] && break
      [[ "$in_rec" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && rec=$((rec + 1))
    done < "$SCHEDULED"
  fi
  fail_count=0; in_fail=0
  while IFS= read -r line; do
    [[ "$line" == "## Falhou" ]] && { in_fail=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_fail" == "1" ]] && break
    [[ "$in_fail" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && fail_count=$((fail_count + 1))
  done < "$KANBAN"

  echo -ne "${B}Kanban:${R} ${DIM}♻${rec}${R}"
  [[ $fail_count -gt 0 ]] && echo -ne " ${RED}✗${fail_count}${R}"
  echo
  count=0
  for item in "${items[@]}"; do
    [[ $count -ge 10 ]] && break
    echo -e "  $item"
    count=$((count + 1))
  done
  remaining=$(( ${#items[@]} - count ))
  [[ $remaining -gt 0 ]] && echo -e "  ${DIM}+${remaining} mais${R}"
fi

exit 0
