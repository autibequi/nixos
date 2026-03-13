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

  # Checar último log do worker (novo path + fallback legado)
  last_log=""
  last_mod=0
  now=$(date +%s)
  # Novo path: .ephemeral/logs/worker-{tier}.log
  if [[ -f "$WS/.ephemeral/logs/worker-${tier}.log" ]]; then
    last_log="$WS/.ephemeral/logs/worker-${tier}.log"
    last_mod=$(stat -c %Y "$last_log" 2>/dev/null || echo 0)
  fi
  # Legado: /workspace/logs/*.log (pegar o mais recente)
  legacy_log=$(ls -t "$WS"/logs/*.log 2>/dev/null | head -1)
  if [[ -n "$legacy_log" ]]; then
    legacy_mod=$(stat -c %Y "$legacy_log" 2>/dev/null || echo 0)
    if [[ "$legacy_mod" -gt "$last_mod" ]]; then
      last_log="$legacy_log"
      last_mod="$legacy_mod"
    fi
  fi

  # Formatar tempo relativo
  fmt_age() {
    local s="$1"
    local h=$(( s / 3600 )) m=$(( (s % 3600) / 60 ))
    if [[ $h -gt 0 ]]; then echo "${h}h${m}m atrás"
    else echo "${m}m atrás"
    fi
  }

  if [[ "$container_state" == "running" ]]; then
    age_str=""
    if [[ -n "$last_log" ]]; then
      age_str=" ${DIM}($(fmt_age $((now - last_mod))))${R}"
    fi
    worker_status+=("${GREEN}🟢 ${tier}${R}${age_str}")
  elif [[ -n "$last_log" ]]; then
    age=$(( now - last_mod ))
    if [[ "$tier" == "fast" ]]; then max_age=900; else max_age=4200; fi
    age_str=" ${DIM}($(fmt_age $age))${R}"

    if [[ "$age" -le "$max_age" ]]; then
      worker_status+=("${GREEN}🟢 ${tier}${R}${age_str}")
    else
      worker_status+=("${YELLOW}🟡 ${tier}${R}${age_str}")
    fi
  else
    worker_status+=("${RED}🔴 ${tier}${R} ${DIM}(nunca executou)${R}")
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

  # Extrair tasks de uma coluna para array
  extract_col() {
    local col="$1" in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## $col" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
        after="${line#*\*\*}"; name="${after%%\*\**}"
        # modelo entre backticks
        model=""
        if [[ "$line" =~ \`([a-z]+)\` ]]; then model=" (${BASH_REMATCH[1]})"; fi
        # descrição após —
        desc=""
        if [[ "$line" == *" — "* ]]; then
          raw_desc="${line##* — }"
          # truncar descrição longa
          if [[ ${#raw_desc} -gt 30 ]]; then raw_desc="${raw_desc:0:27}..."; fi
          desc=" $raw_desc"
        fi
        echo "${name}${model}${desc}"
      fi
    done < "$KANBAN"
  }

  # Concluídos: só de hoje
  extract_done_today() {
    local in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## Concluido" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"$TODAY"* ]]; then
        after="${line#*\*\*}"; name="${after%%\*\**}"
        model=""
        if [[ "$line" =~ \`([a-z]+)\` ]]; then model=" (${BASH_REMATCH[1]})"; fi
        echo "${name}${model}"
      fi
    done < "$KANBAN"
  }

  # Carregar colunas em arrays
  mapfile -t backlog_items < <(extract_col "Backlog")
  mapfile -t doing_items < <(extract_col "Em Andamento")
  mapfile -t done_items < <(extract_done_today)
  mapfile -t fail_items < <(extract_col "Falhou")

  # Recorrentes — só contar
  rec=0
  in_rec=0
  while IFS= read -r line; do
    if [[ "$line" == "## Recorrentes" ]]; then in_rec=1; continue; fi
    if [[ "$line" =~ ^##\  ]] && [[ "$in_rec" == "1" ]]; then break; fi
    if [[ "$in_rec" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then rec=$((rec + 1)); fi
  done < "$KANBAN"

  # Largura das colunas
  COL_W=28

  # Pad/truncar texto pra largura fixa (sem cores)
  pad() {
    local text="$1" w="$2"
    if [[ ${#text} -ge $w ]]; then
      echo "${text:0:$((w-1))}~"
    else
      printf "%-${w}s" "$text"
    fi
  }

  # Header
  echo -e "  ${B}$(pad "📋 Backlog" $COL_W)${R} │ ${B}$(pad "▶ Doing" $COL_W)${R} │ ${B}$(pad "✅ Done (hoje)" $COL_W)${R}"
  echo -e "  $(printf '%.0s─' $(seq 1 $COL_W)) │ $(printf '%.0s─' $(seq 1 $COL_W)) │ $(printf '%.0s─' $(seq 1 $COL_W))"

  # Calcular max rows
  max=${#backlog_items[@]}
  [[ ${#doing_items[@]} -gt $max ]] && max=${#doing_items[@]}
  [[ ${#done_items[@]} -gt $max ]] && max=${#done_items[@]}
  [[ $max -eq 0 ]] && max=1

  for ((i=0; i<max; i++)); do
    b="${backlog_items[$i]:-}"
    d="${doing_items[$i]:-}"
    f="${done_items[$i]:-}"
    # Colorir cada célula
    b_fmt="${DIM}$(pad "$b" $COL_W)${R}"
    [[ -z "$b" ]] && b_fmt="$(pad "" $COL_W)"
    d_fmt="${YELLOW}$(pad "$d" $COL_W)${R}"
    [[ -z "$d" ]] && d_fmt="$(pad "" $COL_W)"
    f_fmt="${GREEN}$(pad "$f" $COL_W)${R}"
    [[ -z "$f" ]] && f_fmt="$(pad "" $COL_W)"
    echo -e "  ${b_fmt} │ ${d_fmt} │ ${f_fmt}"
  done

  # Rodapé com contadores
  total_done=$(extract_col "Concluido" | wc -l)
  echo
  echo -ne "  ${DIM}♻ ${rec} recorrentes${R}"
  [[ ${#fail_items[@]} -gt 0 ]] && echo -ne "  │  ${RED}✗ ${#fail_items[@]} falha(s)${R}"
  echo -e "  │  ${DIM}${total_done} concluída(s) total${R}"
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

    # estrategia é umbrella — só listar dirty/não-main
    if [[ "$proj" == "$ESTRATEGIA_DIR/" ]]; then
      dirty_repos=()
      for sub in "$ESTRATEGIA_DIR"/*/; do
        [[ -d "$sub" ]] || continue
        subname=$(basename "$sub")
        if [[ -d "$sub/.git" ]]; then
          branch=$(git -C "$sub" branch --show-current 2>/dev/null || echo "?")
          dirty=$(git -C "$sub" status --porcelain 2>/dev/null | head -1)
          if [[ -n "$dirty" ]] || [[ "$branch" != "main" && "$branch" != "master" ]]; then
            status="${GREEN}clean${R}"
            [[ -n "$dirty" ]] && status="${YELLOW}dirty${R}"
            dirty_repos+=("    ${DIM}├──${R} ${subname} [${branch}] ${status}")
          fi
        fi
      done
      if [[ ${#dirty_repos[@]} -gt 0 ]]; then
        echo -e "  ${MAGENTA}${name}/${R} ${DIM}(trabalho — ${#dirty_repos[@]} com alterações)${R}"
        for r in "${dirty_repos[@]}"; do echo -e "$r"; done
      else
        echo -e "  ${MAGENTA}${name}/${R} ${DIM}(trabalho — tudo limpo)${R}"
      fi
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
