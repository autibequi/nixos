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

  rec=$(count_cards "Recorrentes")
  back=$(count_cards "Backlog")
  andamento=$(count_cards "Em Andamento")
  done_c=$(count_cards "Concluido")
  fail=$(count_cards "Falhou")

  echo -e "  ${DIM}♻${R} Recorrentes: ${rec}  ${DIM}📋${R} Backlog: ${back}  ${DIM}▶${R} Em Andamento: ${andamento}"
  echo -e "  ${GREEN}✓${R} Concluido: ${done_c}  ${RED}✗${R} Falhou: ${fail}"

  # Mostrar tasks em andamento com worker ID
  if [[ "$andamento" -gt 0 ]]; then
    echo -e "  ${B}Rodando agora:${R}"
    local_in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## Em Andamento" ]]; then local_in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$local_in_col" == "1" ]]; then break; fi
      if [[ "$local_in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
        # Extrair nome e worker
        after="${line#*\*\*}"; name="${after%%\*\**}"
        echo -e "    ${YELLOW}→${R} $name"
      fi
    done < "$KANBAN"
  fi

  # Mostrar tasks interativas (tag #interativo em Em Andamento)
  local_in_col=0
  has_inter=0
  while IFS= read -r line; do
    if [[ "$line" == "## Em Andamento" ]]; then local_in_col=1; continue; fi
    if [[ "$line" =~ ^##\  ]] && [[ "$local_in_col" == "1" ]]; then break; fi
    if [[ "$local_in_col" == "1" ]] && [[ "$line" == *"#interativo"* ]]; then
      if [[ "$has_inter" == "0" ]]; then
        echo -e "  ${B}Interativas (retomáveis):${R}"
        has_inter=1
      fi
      after="${line#*\*\*}"; name="${after%%\*\**}"
      echo -e "    ${CYAN}⚡${R} $name"
    fi
  done < "$KANBAN"
else
  echo -e "${B}Kanban:${R} ${DIM}(vault/kanban.md não encontrado)${R}"
fi
echo

# --- Workspace tree nível 1 ---
echo -e "${B}Workspace:${R}"
for item in "$WS"/*/; do
  name=$(basename "$item")
  [[ "$name" == ".git" || "$name" == ".claude" || "$name" == ".ephemeral" ]] && continue
  echo -e "  ${DIM}├──${R} $name/"
done
for item in "$WS"/*.nix "$WS"/makefile "$WS"/CLAUDE.md; do
  [[ -f "$item" ]] && echo -e "  ${DIM}├──${R} $(basename "$item")"
done
echo

# --- Projetos ---
echo -e "${B}Projetos:${R}"
has_projects=false
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
$has_projects || echo -e "  ${DIM}(nenhum)${R}"

echo
echo -e "${DIM}─── pronto pra trabalhar ───${R}"
