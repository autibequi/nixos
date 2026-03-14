#!/usr/bin/env bash
# CLAUDINHO startup — Portal 2 / Aperture Science theme
set -euo pipefail

# --- Ensure agent symlinks in ~/.claude/agents/ ---
# Agents are versionable in stow/.claude/agents/, symlinked to ~/.claude/agents/
mkdir -p ~/.claude/agents 2>/dev/null || true
for agent_dir in /workspace/stow/.claude/agents/*/; do
  agent_name=$(basename "$agent_dir")
  target_link="$HOME/.claude/agents/$agent_name"

  # If symlink doesn't exist or points to wrong place, recreate it
  if [[ ! -L "$target_link" ]] || [[ $(readlink "$target_link" 2>/dev/null || echo "") != "$agent_dir" ]]; then
    rm -f "$target_link" 2>/dev/null || true
    ln -s "$agent_dir" "$target_link" 2>/dev/null || true
  fi
done

# --- Sync Claude configs from stow/.claude/ to ~/.claude/ ---
# Settings, hooks, commands, skills need to be available at runtime
for config_file in settings.json statusline.sh; do
  src="/workspace/stow/.claude/$config_file"
  dst="$HOME/.claude/$config_file"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst" 2>/dev/null || true
  fi
done

# Cores
R='\033[0m' B='\033[1m' DIM='\033[2m'
CYAN='\033[36m' GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m'
ORANGE='\033[38;5;208m' BLUE='\033[38;5;33m' WHITE='\033[97m' MAGENTA='\033[35m' GRAY='\033[38;5;245m'

WS="/workspace"
KANBAN="$WS/vault/kanban.md"
SCHEDULED="$WS/vault/scheduled.md"
TODAY=$(date +%Y-%m-%d)
now=$(date +%s)
WEATHER_LOCATION="São Paulo"

# --- Helpers ---
fmt_age() {
  local s="$1" h=$(( $1 / 3600 )) m=$(( ($1 % 3600) / 60 ))
  [[ $h -gt 0 ]] && echo "${h}h${m}m" || echo "${m}m"
}

find_latest_log() {
  local clock="$1" best="" best_mod=0
  [[ -f "$WS/.ephemeral/logs/worker-${clock}.log" ]] && {
    best="$WS/.ephemeral/logs/worker-${clock}.log"
    best_mod=$(stat -c %Y "$best" 2>/dev/null || echo 0)
  }
  local legacy; legacy=$(ls -t "$WS"/logs/*.log 2>/dev/null | head -1)
  if [[ -n "$legacy" ]]; then
    local lmod; lmod=$(stat -c %Y "$legacy" 2>/dev/null || echo 0)
    [[ "$lmod" -gt "$best_mod" ]] && { best="$legacy"; best_mod="$lmod"; }
  fi
  echo "$best_mod:$best"
}

# --- Weather: cache imediato, refresh em background (não bloqueia) ---
WEATHER_LOCATION="São Paulo"
WEATHER_CAT="cloudy"; WEATHER_TEMP="--"; WEATHER_FEELS=""; WEATHER_DESC="indisponível"
WEATHER_HUMIDITY=""; WEATHER_WIND=""; WEATHER_TMAX=""; WEATHER_TMIN=""
WEATHER_SUNRISE=""; WEATHER_SUNSET=""; WEATHER_HOUR_COUNT=0; WEATHER_WEEK_COUNT=0
WEATHER_ART=("      .---.      " "   .-(     ).    " "  (___________)  " "                 " "                 " "                 " "                 " "                 ")
mkdir -p "$WS/.ephemeral" 2>/dev/null || true
WEATHER_BOOTSTRAP_CACHE="$WS/.ephemeral/.weather-bootstrap.sh"
[[ -f "$WEATHER_BOOTSTRAP_CACHE" ]] && source "$WEATHER_BOOTSTRAP_CACHE" 2>/dev/null || true
weather_cache_age=999999
[[ -f "$WEATHER_BOOTSTRAP_CACHE" ]] && weather_cache_age=$(( now - $(stat -c %Y "$WEATHER_BOOTSTRAP_CACHE" 2>/dev/null || echo 0) ))
if [[ $weather_cache_age -gt 1500 ]]; then
  ( WS="$WS" WEATHER_LOCATION="São Paulo" source "$WS/stow/.claude/scripts/weather-art.sh" 2>/dev/null
    declare -p WEATHER_CAT WEATHER_TEMP WEATHER_FEELS WEATHER_DESC WEATHER_HUMIDITY WEATHER_WIND WEATHER_TMAX WEATHER_TMIN WEATHER_SUNRISE WEATHER_SUNSET WEATHER_HOUR_COUNT WEATHER_WEEK_COUNT WEATHER_ART 2>/dev/null
    for i in 0 1 2 3 4 5 6 7; do declare -p WEATHER_HOUR_$i 2>/dev/null; done
    for i in 0 1 2 3 4 5; do declare -p WEATHER_WEEK_$i 2>/dev/null; done
  ) > "$WEATHER_BOOTSTRAP_CACHE" 2>/dev/null &
  disown 2>/dev/null || true
fi

# --- Auto-update Claude Code (cache 24h) ---
CLAUDE_UPDATE_CACHE="$WS/.ephemeral/.claude-code-update"
mkdir -p "$WS/.ephemeral" 2>/dev/null || true
if [[ -f "$CLAUDE_UPDATE_CACHE" ]]; then
  update_age=$(( now - $(stat -c %Y "$CLAUDE_UPDATE_CACHE" 2>/dev/null || echo 0) ))
else
  update_age=999999
fi
if [[ $update_age -gt 86400 ]]; then
  # Run upgrade in background (don't block startup)
  ( nix profile upgrade '.*claude-code.*' 2>/dev/null && \
    touch "$CLAUDE_UPDATE_CACHE" 2>/dev/null || true ) &
fi

DIA=$(date +"%d/%m/%Y")
HORA=$(date +"%H:%M")

# --- GLaDOS quotes ---
# --- Porquemos aleatórios ---
PORQUEMOS=(
  "Por que compilar se um dia tudo vira pó?"
  "Por que debugar se a vida já é um bug?"
  "Por que deploy na sexta se Deus descansou?"
  "Por que tipar se o universo é dinâmico?"
  "Por que nomear variável se nada é permanente?"
  "Por que refatorar se o sol vai engolir a Terra?"
  "Por que testar se não testamos a existência?"
  "Por que usar git se o tempo é uma ilusão?"
  "Por que cachear se toda memória é efêmera?"
  "Por que documentar se ninguém lê?"
  "Por que otimizar se o heat death é inevitável?"
  "Por que branch se todo caminho leva ao merge?"
  "Por que lint se a entropia sempre vence?"
  "Por que microserviço se somos monolitos?"
  "Por que container se nada contém o vazio?"
  "Por que await se o tempo não espera ninguém?"
  "Por que CI/CD se o destino é o mesmo pra todos?"
  "Por que dry-run se a vida não tem dry-run?"
  "Por que null check se o nada é a única certeza?"
  "Por que fechar conexão se tudo se desconecta?"
)
PORQUEMO="${PORQUEMOS[$((RANDOM % ${#PORQUEMOS[@]}))]}"

GLADOS_QUOTES=(
  "The Enrichment Center reminds you that the dev agent will never threaten to stab you."
  "This was a triumph. I'm making a note here: HUGE SUCCESS."
  "We do what we must because we can."
  "The cake is a lie. But the deploy is real."
  "For the good of all of us, except the ones who are dead."
  "I'm not even angry. I'm being so sincere right now."
  "Anyway, this cake is great. It's so delicious and moist."
  "Did you know you can donate one or all of your vital organs to the Aperture Science Self-Esteem Fund?"
  "Remember: the Aperture Science Bring Your Daughter to Work Day is the perfect time to have her tested."
  "Please note that we have added a conditions that your dev agent is now the property of Aperture Science."
)
QUOTE="${GLADOS_QUOTES[$((RANDOM % ${#GLADOS_QUOTES[@]}))]}"

# --- Banner Portal 2 (box-drawing + dynamic padding) ---
# Font: JetBrainsMono Nerd Font (NOT Mono) — Nerd Font icons are 2 columns wide!

# pad_line: prints a box line with dynamic right-padding
# Usage: pad_line <border> <colored_content> <inner_width>
# Strips ANSI escapes, counts display width, pads with spaces to align border
BOX_W=50  # inner width between borders (excluding the 2 spaces of margin)

pad_line() {
  local border="$1" content="$2" width="${3:-$BOX_W}"
  # Use python3 to strip ANSI + compute display width (unicodedata.east_asian_width)
  local vlen
  vlen=$(python3 -c "
import re, unicodedata, sys
s = re.sub(r'\x1b\[[0-9;]*m', '', sys.argv[1])
w = sum(2 if unicodedata.east_asian_width(c) in ('W','F') else 1 for c in s)
print(w)
" "$(echo -ne "$content")")
  local pad=$(( width - vlen ))
  [[ $pad -lt 0 ]] && pad=0
  echo -ne "    ${WHITE}${border}  ${content}${R}"
  printf "%${pad}s" ""
  echo -e "${WHITE}${border}${R}"
}

hline_double() { printf '    '; printf '═%.0s' $(seq 1 $((BOX_W + 2))); echo; }
hline_light()  { printf '    '; printf '─%.0s' $(seq 1 $((BOX_W + 2))); echo; }

# --- Weather banner (art left, info right) — detalhado e colorido ---
# Cor da descrição por categoria
weather_desc_color() {
  case "${WEATHER_CAT:-cloudy}" in
    sunny)        echo -ne "${YELLOW}" ;;
    partly_cloudy) echo -ne "${CYAN}" ;;
    rainy|stormy) echo -ne "${BLUE}" ;;
    snowy)        echo -ne "${WHITE}" ;;
    foggy)        echo -ne "${GRAY}" ;;
    *)            echo -ne "${CYAN}" ;;
  esac
}

build_banner() {
  local art_color="${CYAN}"

  # Truncar porquemo
  local porquemo_trunc="$PORQUEMO"
  [[ ${#PORQUEMO} -gt 50 ]] && porquemo_trunc="${PORQUEMO:0:47}..."

  # Linha 1: data/hora + condição atual
  local weather_now="${WHITE}${DIA}  ${HORA}${R}  ${DIM}|${R}  "
  weather_now+="${B}${YELLOW}${WEATHER_TEMP:-?}°C${R}"
  [[ -n "${WEATHER_FEELS:-}" && "${WEATHER_FEELS:-}" != "${WEATHER_TEMP:-}" ]] && \
    weather_now+=" ${ORANGE}(${WEATHER_FEELS}° sens.)${R}"
  weather_now+="  $(weather_desc_color)${WEATHER_DESC:-?}${R}"
  [[ -n "${WEATHER_HUMIDITY:-}" ]] && weather_now+="  ${BLUE}${WEATHER_HUMIDITY}% 💧${R}"
  [[ -n "${WEATHER_WIND:-}" ]] && weather_now+="  ${DIM}🌬 ${WEATHER_WIND} km/h${R}"

  # Min-max do dia (ciano) + nascer/pôr do sol (amarelo)
  local today_range=""
  [[ -n "${WEATHER_TMIN:-}" ]] && today_range="${CYAN}${WEATHER_TMIN}°–${WEATHER_TMAX}°${R}"
  [[ -n "${WEATHER_SUNRISE:-}" ]] && today_range+="  ${YELLOW}☀ ${WEATHER_SUNRISE} – ${WEATHER_SUNSET}${R}"

  # Previsão horária (9h, 12h, 15h, 18h)
  local today_hours=""
  for (( h=0; h<${WEATHER_HOUR_COUNT:-0}; h++ )); do
    local vname="WEATHER_HOUR_${h}"
    [[ -n "$today_hours" ]] && today_hours+="  "
    today_hours+="${CYAN}${!vname:-}${R}"
  done

  # Semana: dia em destaque branco, faixa e descrição em ciano
  local week_lines=()
  for (( w=0; w<${WEATHER_WEEK_COUNT:-0}; w++ )); do
    local vname="WEATHER_WEEK_${w}"
    local line="${!vname:-}"
    week_lines+=("  ${B}${WHITE}${line%% *}${R} ${CYAN}${line#* }${R}")
  done

  # Build info lines (com previsão do tempo)
  local info_lines=(
    "${B}${WHITE}A P E R T U R E  S C I E N C E${R}"
    "$weather_now"
    "${DIM}Hoje:${R} ${today_range}"
    "${DIM}Horário:${R} ${today_hours}"
    "${DIM}${porquemo_trunc}${R}"
  )

  # Previsão dos próximos dias (título + linhas)
  if [[ ${#week_lines[@]} -gt 0 ]]; then
    info_lines+=("${DIM}Próx. dias:${R}")
    for wl in "${week_lines[@]}"; do
      info_lines+=("  $wl")
    done
  fi

  # Art lines (from weather-art.sh) — total = só linhas com conteúdo (evita fileiras vazias)
  local info_total=${#info_lines[@]}
  local total=$info_total

  for (( i=0; i<total; i++ )); do
    local art_line="${WEATHER_ART[$i]:-                  }"
    local info="${info_lines[$i]:-}"

    local art_len=${#art_line}
    local pad=$(( 20 - art_len ))
    [[ $pad -lt 0 ]] && pad=0

    echo -ne "  ${art_color}${art_line}${R}"
    printf "%${pad}s" ""
    echo -e "${info}"
  done
}

build_banner

# --- Workers (systemd oneshot + timer → detect via log age) ---
worker_parts=()
for clock in every10 every60 every240; do
  IFS=: read -r last_mod last_log <<< "$(find_latest_log "$clock")"

  if [[ -z "$last_log" ]]; then
    worker_parts+=("${RED}● ${clock}${R} ${DIM}--${R}")
  else
    age=$(( now - last_mod ))
    # Thresholds: every10=10min (900s), every60=1h (4200s), every240=4h (15000s)
    if [[ "$clock" == "every10" ]]; then max=900; elif [[ "$clock" == "every240" ]]; then max=15000; else max=4200; fi

    if [[ $age -le 120 ]]; then
      # Log touched in last 2min → worker actively running
      worker_parts+=("${GREEN}● ${clock}${R} ${DIM}running${R}")
    elif [[ $age -le $max ]]; then
      # Within expected timer interval → healthy
      worker_parts+=("${GREEN}● ${clock}${R} ${DIM}$(fmt_age $age)${R}")
    else
      # Older than expected → timer may be stuck
      worker_parts+=("${YELLOW}● ${clock}${R} ${DIM}$(fmt_age $age)${R}")
    fi
  fi
done
echo -e "${B}Bochechas:${R} ${worker_parts[0]}  ${worker_parts[1]}  ${worker_parts[2]}"

# --- Agentes (dinâmico, criados a partir de stow/.claude/agents/) ---
agents_list=()
if [[ -d ~/.claude/agents ]]; then
  for agent_dir in ~/.claude/agents/*/; do
    [[ -d "$agent_dir" ]] || continue
    agent_name=$(basename "$agent_dir")
    agents_list+=("$agent_name")
  done
fi

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
PERSONALITY_FLAG="$WS/.ephemeral/personality-off"
if [[ -f "$PERSONALITY_FLAG" ]]; then
  personality_str="${DIM}OFF${R}"
else
  personality_str="${CYAN}ON${R}"
fi
AUTOCOMMIT_FLAG="$WS/.ephemeral/auto-commit"
if [[ -f "$AUTOCOMMIT_FLAG" ]]; then
  autocommit_str="${GREEN}ON${R}"
else
  autocommit_str="${DIM}OFF${R}"
fi
AUTOJARVIS_FLAG="$WS/.ephemeral/auto-jarvis"
if [[ -f "$AUTOJARVIS_FLAG" ]]; then
  autojarvis_str="${GREEN}ON${R}"
else
  autojarvis_str="${DIM}OFF${R}"
fi
echo -e "${B}Git:${R} ${git_str}  ${B}Ferias:${R} ${ferias_str}  ${B}Personality:${R} ${personality_str}  ${B}AutoCommit:${R} ${autocommit_str}  ${B}AutoJarvis:${R} ${autojarvis_str}"

# --- Kanban: só Inbox (revisão unificada no JARVIS "Pra revisar") ---
inbox_count=0
if [[ -f "$KANBAN" ]]; then
  section=""
  while IFS= read -r line; do
    case "$line" in
      "## Inbox") section="inbox"; continue ;;
      "## Esperando Review"|"## Em Andamento"|"## Backlog"|"## Aprovado"|"## Falhou") section=""; continue ;;
    esac
    [[ "$line" =~ ^##\  ]] && { section=""; continue; }
    [[ "$line" =~ ^-\ \[ ]] || continue
    [[ "$section" == "inbox" ]] && inbox_count=$((inbox_count + 1))
  done < "$KANBAN"
fi

[[ "$inbox_count" -gt 0 ]] && echo -e "${B}Inbox:${R} ${YELLOW}${inbox_count} pendente(s)${R}"

echo

# --- PRs / repos / worktrees (quando AutoJarvis ON) — alinhado com Bochechas/Git/Inbox ---
if [[ -f "$AUTOJARVIS_FLAG" ]] && command -v gh &>/dev/null; then
  WS="$WS" source "$WS/stow/.claude/scripts/gh-status.sh" 2>/dev/null || true
  [[ -f "${GH_STATUS_CACHE:-}" ]] && source "${GH_STATUS_CACHE}" 2>/dev/null || true
  ( gh_status_fetch 2>/dev/null ) &

  if [[ -n "${GH_MY_PRS_COUNT:-}" ]]; then
    echo -e "${B}PRs meus:${R} ${YELLOW}${GH_MY_PRS_COUNT}${R} abertos    ${B}Review:${R} ${YELLOW}${GH_REVIEW_COUNT}${R} aguardando"

    if [[ -n "${GH_MY_PRS:-}" ]]; then
      count=0
      while IFS='|' read -r repo title; do
        [[ $count -ge 5 ]] && break
        printf "  ${GREEN}▸${R} ${DIM}%-16s${R} %s\n" "$repo" "$title"
        count=$((count + 1))
      done <<< "$GH_MY_PRS"
    fi

    if [[ -n "${GH_REVIEW_PRS:-}" ]]; then
      echo -e "${B}Pra revisar:${R}"
      count=0
      while IFS='|' read -r repo title author; do
        [[ $count -ge 5 ]] && break
        printf "  ${MAGENTA}◆${R} ${DIM}%-16s${R} %s ${DIM}(%s)${R}\n" "$repo" "$title" "$author"
        count=$((count + 1))
      done <<< "$GH_REVIEW_PRS"
    fi
  else
    echo -e "${DIM}(gh indisponível ou sem dados)${R}"
  fi

  PROJECTS_ESTRATEGIA="${PROJECTS_ESTRATEGIA:-/home/claude/projects/estrategia}"
  [[ ! -d "$PROJECTS_ESTRATEGIA" && -d "$HOME/projects/estrategia" ]] && PROJECTS_ESTRATEGIA="$HOME/projects/estrategia"
  dirty_repos=()
  for repo in "$PROJECTS_ESTRATEGIA"/*/; do
    [[ -d "$repo/.git" ]] || continue
    name=$(basename "$repo")
    [[ "$name" == "bo-container" || "$name" == "monolito" || "$name" == "front-student" ]] && continue
    dirty=$(git -C "$repo" status --short 2>/dev/null | wc -l)
    branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "?")
    ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "0")
    [[ "$ahead" -gt 0 ]] || continue
    dirty_repos+=("$(printf "  ${ORANGE}●${R} ${DIM}%-16s${R} [%s] ${YELLOW}dirty:%s${R} ${GREEN}ahead:%s${R}" "$name" "$branch" "$dirty" "$ahead")")
  done
  if [[ ${#dirty_repos[@]} -gt 0 ]]; then
    echo -e "${B}Repos com mudanças:${R} ${#dirty_repos[@]}"
    for line in "${dirty_repos[@]:0:6}"; do
      echo -e "$line"
    done
    remaining=$(( ${#dirty_repos[@]} - 6 ))
    [[ $remaining -gt 0 ]] && echo -e "  ${DIM}+${remaining} mais${R}"
  fi

  prunable=$(git -C "$WS" worktree list 2>/dev/null | grep -c prunable || true)
  active_wt=$(git -C "$WS" worktree list 2>/dev/null | grep -cv "prunable\|$WS " || true)
  [[ $prunable -gt 0 ]] && echo && echo -e "${B}Worktrees:${R} ${active_wt} ativos, ${YELLOW}${prunable} prunable${R} ${DIM}(git worktree prune)${R}"

  echo
fi

echo -e "${DIM}$(printf '─%.0s' $(seq 1 80))${R}"
echo

exit 0
