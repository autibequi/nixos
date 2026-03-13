#!/usr/bin/env bash
# Claudinho startup — mostra estado do workspace rapidamente

set -euo pipefail

# Cores
R='\033[0m'
B='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RED='\033[31m'

WS="/workspace"
KANBAN="$WS/vault/kanban.md"
TODAY=$(date +%Y-%m-%d)

# --- Trocadilho aleatório ---
PUNS=(
  "Claud-íssimo"
  "Claud-estino"
  "Claud-ificado"
  "Claud-aluz"
  "Claud-inâmica"
  "Claud-etonante"
  "Claud-eroso"
  "Claud-emaravilha"
)
PUN="${PUNS[$((RANDOM % ${#PUNS[@]}))]}"

echo -e "${B}${CYAN}${PUN}${R} presente! ⚡"
echo

# --- Status dos workers (via podman socket + logs) ---
echo -ne "${B}Workers:${R} "
worker_status=()
for tier in fast heavy; do
  container="clau-worker-${tier}"
  # Checar container via podman socket
  container_state=""
  if [[ -S /host/podman.sock ]]; then
    container_state=$(curl -s --unix-socket /host/podman.sock \
      "http://d/v4.0.0/libpod/containers/${container}/json" 2>/dev/null \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['State']['Status'])" 2>/dev/null || true)
  fi

  # Checar último log do worker em /workspace/logs/
  last_log=$(ls -t "$WS"/logs/*.log 2>/dev/null | head -1)
  now=$(date +%s)

  if [[ "$container_state" == "running" ]]; then
    worker_status+=("${GREEN}🟢 ${tier}${R}")
  elif [[ -n "$last_log" ]]; then
    last_mod=$(stat -c %Y "$last_log" 2>/dev/null || echo 0)
    age=$(( now - last_mod ))
    if [[ "$tier" == "fast" ]]; then max_age=900; else max_age=4200; fi
    # Checar conteúdo do log mais recente
    last_lines=$(tail -10 "$last_log" 2>/dev/null)
    if ! echo "$last_lines" | grep -qE "\[clau:.*${tier}|CLAU_TIER=${tier}" 2>/dev/null; then
      # Log não é desse tier, tentar achar o log certo
      tier_log=$(grep -lE "CLAU_TIER=${tier}|\[clau:.*:${tier}\]" "$WS"/logs/*.log 2>/dev/null | tail -1 || true)
      if [[ -n "$tier_log" ]]; then
        last_mod=$(stat -c %Y "$tier_log" 2>/dev/null || echo 0)
        age=$(( now - last_mod ))
        last_lines=$(tail -10 "$tier_log" 2>/dev/null)
      fi
    fi

    if [[ "$age" -le "$max_age" ]]; then
      worker_status+=("${GREEN}🟢 ${tier}${R} ${DIM}($(( age / 60 ))m atrás)${R}")
    else
      hrs=$(( age / 3600 ))
      mins=$(( (age % 3600) / 60 ))
      if [[ "$hrs" -gt 0 ]]; then
        worker_status+=("${YELLOW}🟡 ${tier}${R} ${DIM}(${hrs}h${mins}m atrás)${R}")
      else
        worker_status+=("${YELLOW}🟡 ${tier}${R} ${DIM}(${mins}m atrás)${R}")
      fi
    fi
  else
    worker_status+=("${RED}🔴 ${tier}${R} ${DIM}(sem atividade)${R}")
  fi
done
echo -e "${worker_status[0]}  ${worker_status[1]}"
echo

# --- Modo trabalho/férias ---
MODE_FILE="$WS/projetos/CLAUDE.md"
if [[ -f "$MODE_FILE" ]]; then
  if grep -q 'FÉRIAS \[OFF\]' "$MODE_FILE" 2>/dev/null; then
    echo -e "${B}Modo:${R} 🔥 TRABALHO (férias OFF)"
  else
    echo -e "${B}Modo:${R} 🌴 FÉRIAS"
  fi
else
  echo -e "${B}Modo:${R} ${DIM}pessoal${R}"
fi
echo

# --- Inbox ---
INBOX_DIR="$WS/vault/inbox"
if [[ -d "$INBOX_DIR" ]]; then
  inbox_count=$(find "$INBOX_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l)
  if [[ "$inbox_count" -gt 0 ]]; then
    echo -e "${B}Inbox:${R} ${YELLOW}${inbox_count} mensagem(ns) pendente(s)${R}"
    echo
  fi
fi

# --- Kanban resumo ---
if [[ -f "$KANBAN" ]]; then
  echo -e "${B}Kanban:${R}"

  # Contar cards por coluna
  count_cards() {
    local col="$1"
    local in_col=0 count=0
    while IFS= read -r line; do
      if [[ "$line" == "## $col" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then count=$((count + 1)); fi
    done < "$KANBAN"
    echo "$count"
  }

  # Contar concluídos de hoje
  count_done_today() {
    local in_col=0 count=0
    while IFS= read -r line; do
      if [[ "$line" == "## Concluido" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"$TODAY"* ]]; then
        count=$((count + 1))
      fi
    done < "$KANBAN"
    echo "$count"
  }

  rec=$(count_cards "Recorrentes")
  back=$(count_cards "Backlog")
  andamento=$(count_cards "Em Andamento")
  done_c=$(count_cards "Concluido")
  done_today=$(count_done_today)
  fail=$(count_cards "Falhou")

  # Linha resumo — recorrentes só contador, concluído só hoje
  echo -e "  ♻ ${rec} recorrentes  │  ▶ ${andamento} em andamento  │  📋 ${back} backlog"
  summary_line="  ${GREEN}✓${R} ${done_today} concluída(s) hoje (${done_c} total)"
  [[ "$fail" -gt 0 ]] && summary_line+="  │  ${RED}✗ ${fail} falha(s)${R}"
  echo -e "$summary_line"

  # Helper: listar tasks de uma coluna
  list_tasks() {
    local col="$1" icon="$2" color="$3"
    local in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## $col" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
        after="${line#*\*\*}"; name="${after%%\*\**}"
        # Extrair modelo se presente (entre backticks)
        model=""
        if [[ "$line" =~ \`([a-z]+)\` ]]; then model=" ${DIM}(${BASH_REMATCH[1]})${R}"; fi
        # Extrair descrição após o — se existir
        desc=""
        if [[ "$line" == *" — "* ]]; then desc=" ${DIM}— ${line##* — }${R}"; fi
        echo -e "    ${color}${icon}${R} ${name}${model}${desc}"
      fi
    done < "$KANBAN"
  }

  # Helper: listar backlog com idade
  list_backlog() {
    local in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## Backlog" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
        after="${line#*\*\*}"; name="${after%%\*\**}"
        model=""
        if [[ "$line" =~ \`([a-z]+)\` ]]; then model=" ${DIM}(${BASH_REMATCH[1]})${R}"; fi
        desc=""
        if [[ "$line" == *" — "* ]]; then desc=" ${DIM}— ${line##* — }${R}"; fi
        # Calcular idade se tiver data
        age=""
        if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
          task_date="${BASH_REMATCH[1]}"
          days_ago=$(( ($(date -d "$TODAY" +%s) - $(date -d "$task_date" +%s)) / 86400 ))
          if [[ "$days_ago" -eq 0 ]]; then
            age=" ${DIM}(hoje)${R}"
          elif [[ "$days_ago" -eq 1 ]]; then
            age=" ${DIM}(ontem)${R}"
          elif [[ "$days_ago" -le 7 ]]; then
            age=" ${DIM}(${days_ago}d)${R}"
          else
            age=" ${YELLOW}(${days_ago}d!)${R}"
          fi
        fi
        echo -e "    ${DIM}○${R} ${name}${model}${age}${desc}"
      fi
    done < "$KANBAN"
  }

  # Mostrar tasks em andamento
  if [[ "$andamento" -gt 0 ]]; then
    echo -e "  ${B}Rodando agora:${R}"
    list_tasks "Em Andamento" "→" "$YELLOW"
  fi

  # Mostrar backlog com idade
  if [[ "$back" -gt 0 ]]; then
    echo -e "  ${B}Backlog:${R}"
    list_backlog
  fi

  # Mostrar falhas se houver
  if [[ "$fail" -gt 0 ]]; then
    echo -e "  ${B}Falharam:${R}"
    list_tasks "Falhou" "✗" "$RED"
  fi
else
  echo -e "${B}Kanban:${R} ${DIM}(vault/kanban.md não encontrado)${R}"
fi
echo

# --- Git status workspace ---
echo -ne "${B}Workspace git:${R} "
ws_branch=$(git -C "$WS" branch --show-current 2>/dev/null || echo "?")
ws_dirty=$(git -C "$WS" status --porcelain 2>/dev/null | head -1)
ws_ahead=$(git -C "$WS" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
ws_behind=$(git -C "$WS" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
echo -ne "[${ws_branch}] "
if [[ -n "$ws_dirty" ]]; then
  echo -ne "${YELLOW}dirty${R} "
else
  echo -ne "${GREEN}clean${R} "
fi
sync_info=""
[[ "$ws_ahead" -gt 0 ]] && sync_info+="${GREEN}↑${ws_ahead}${R} "
[[ "$ws_behind" -gt 0 ]] && sync_info+="${RED}↓${ws_behind}${R} "
[[ -n "$sync_info" ]] && echo -ne "$sync_info"
echo
echo

# --- Projetos ---
echo -e "${B}Projetos:${R}"
has_projects=false

# Projetos do workspace (submódulos)
for proj in "$WS"/projetos/*/; do
  [[ -d "$proj" ]] || continue
  name=$(basename "$proj")
  [[ "$name" == "CLAUDE.md" ]] && continue
  has_projects=true
  if [[ -d "$proj/.git" ]]; then
    branch=$(git -C "$proj" branch --show-current 2>/dev/null || echo "?")
    dirty=$(git -C "$proj" status --porcelain 2>/dev/null | head -1)
    status="${GREEN}clean${R}"
    [[ -n "$dirty" ]] && status="${YELLOW}dirty${R}"
    echo -e "  ${MAGENTA}${name}${R} [${branch}] ${status}"
  else
    echo -e "  ${MAGENTA}${name}${R} ${DIM}(no git)${R}"
  fi
done

# Projetos de ~/projects
PROJECTS_DIR="/home/claude/projects"
ESTRATEGIA_DIR="$PROJECTS_DIR/estrategia"
if [[ -d "$PROJECTS_DIR" ]]; then
  for proj in "$PROJECTS_DIR"/*/; do
    [[ -d "$proj" ]] || continue
    name=$(basename "$proj")
    has_projects=true

    # estrategia é umbrella — expandir sub-repos
    if [[ "$proj" == "$ESTRATEGIA_DIR/" ]]; then
      echo -e "  ${MAGENTA}${name}/${R} ${DIM}(trabalho)${R}"
      for sub in "$ESTRATEGIA_DIR"/*/; do
        [[ -d "$sub" ]] || continue
        subname=$(basename "$sub")
        if [[ -d "$sub/.git" ]]; then
          branch=$(git -C "$sub" branch --show-current 2>/dev/null || echo "?")
          dirty=$(git -C "$sub" status --porcelain 2>/dev/null | head -1)
          status="${GREEN}clean${R}"
          [[ -n "$dirty" ]] && status="${YELLOW}dirty${R}"
          echo -e "    ${DIM}├──${R} ${subname} [${branch}] ${status}"
        else
          echo -e "    ${DIM}├──${R} ${subname} ${DIM}(no git)${R}"
        fi
      done
      continue
    fi

    if [[ -d "$proj/.git" ]]; then
      branch=$(git -C "$proj" branch --show-current 2>/dev/null || echo "?")
      dirty=$(git -C "$proj" status --porcelain 2>/dev/null | head -1)
      status="${GREEN}clean${R}"
      [[ -n "$dirty" ]] && status="${YELLOW}dirty${R}"
      echo -e "  ${MAGENTA}${name}${R} [${branch}] ${status}"
    else
      echo -e "  ${MAGENTA}${name}${R} ${DIM}(no git)${R}"
    fi
  done
fi

$has_projects || echo -e "  ${DIM}(nenhum)${R}"

echo
echo -e "${DIM}─── pronto pra trabalhar ───${R}"
