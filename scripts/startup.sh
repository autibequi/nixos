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

WS="/workspace"

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
  # Git info
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

# --- Tasks pending ---
echo -e "${B}Tasks pending:${R}"
PENDING="$WS/tasks/pending"
if [[ -d "$PENDING" ]] && ls "$PENDING"/*/ >/dev/null 2>&1; then
  for task in "$PENDING"/*/; do
    name=$(basename "$task")
    # Ler model do frontmatter
    model=""
    if [[ -f "$task/CLAUDE.md" ]]; then
      in_fm=false
      while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
          $in_fm && break
          in_fm=true; continue
        fi
        $in_fm && [[ "$line" == model:* ]] && model="${line#model:}" && model="${model# }" && break
      done < "$task/CLAUDE.md"
    fi
    [[ -n "$model" ]] && model=" ${DIM}(${model})${R}"
    echo -e "  • ${name}${model}"
  done
else
  echo -e "  ${DIM}(nenhuma)${R}"
fi

# --- Tasks recurring ---
RECURRING="$WS/tasks/recurring"
if [[ -d "$RECURRING" ]] && ls "$RECURRING"/*/ >/dev/null 2>&1; then
  echo
  echo -e "${B}Tasks recurring:${R}"
  for task in "$RECURRING"/*/; do
    name=$(basename "$task")
    schedule=""
    if [[ -f "$task/CLAUDE.md" ]]; then
      in_fm=false
      while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
          $in_fm && break
          in_fm=true; continue
        fi
        $in_fm && [[ "$line" == schedule:* ]] && schedule="${line#schedule:}" && schedule="${schedule# }" && break
      done < "$task/CLAUDE.md"
    fi
    [[ -n "$schedule" ]] && schedule=" ${DIM}(${schedule})${R}"
    echo -e "  ♻ ${name}${schedule}"
  done
fi

echo
echo -e "${DIM}─── pronto pra trabalhar ───${R}"
