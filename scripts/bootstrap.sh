#!/usr/bin/env bash
# CLAUDINHO startup — Portal 2 / Aperture Science theme
set -euo pipefail

# Limpa output anterior (docker compose up, etc.)
printf '\033c'

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

# Tema: terminal de fósforo com cores (CRT glow)
R='\033[0m' B='\033[1m' DIM='\033[2m'
# Fosforo: brilho saturado (bold bright)
P_GREEN='\033[1;92m'   # fosforo verde
P_AMBER='\033[1;93m'   # âmbar
P_CYAN='\033[1;96m'    # ciano
P_MAGENTA='\033[1;95m' # magenta
P_RED='\033[1;91m'     # vermelho
P_DIM='\033[2;36m'     # scanline / secundário (dim cyan)
# Fallback 256
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

USAGE_BAR_FILE="$WS/.ephemeral/usage-bar.txt"
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

# Bordes no estilo CRT (dim cyan)
pad_line() {
  local border="$1" content="$2" width="${3:-$BOX_W}"
  local vlen
  vlen=$(python3 -c "
import re, unicodedata, sys
s = re.sub(r'\x1b\[[0-9;]*m', '', sys.argv[1])
w = sum(2 if unicodedata.east_asian_width(c) in ('W','F') else 1 for c in s)
print(w)
" "$(echo -ne "$content")")
  local pad=$(( width - vlen ))
  [[ $pad -lt 0 ]] && pad=0
  echo -ne "    ${P_DIM}${border}  ${content}${R}"
  printf "%${pad}s" ""
  echo -e "${P_DIM}${border}${R}"
}

# --- Modo banner: auto (por tamanho do terminal), compact, full ---
# BOOTSTRAP_BANNER=compact | full | auto (default)
BOOTSTRAP_BANNER="${BOOTSTRAP_BANNER:-auto}"
COLS="${COLUMNS:-$(tput cols 2>/dev/null || echo 100)}"
LINS="${LINES:-$(tput lines 2>/dev/null || echo 30)}"
[[ "$BOOTSTRAP_BANNER" == "auto" ]] && { [[ "$COLS" -lt 90 || "$LINS" -lt 22 ]] && BOOTSTRAP_BANNER="compact" || BOOTSTRAP_BANNER="full"; }

# Cor da descrição (fosforo)
weather_desc_color() {
  case "${WEATHER_CAT:-cloudy}" in
    sunny)        echo -ne "${P_AMBER}" ;;
    partly_cloudy) echo -ne "${P_CYAN}" ;;
    rainy|stormy) echo -ne "${P_CYAN}" ;;
    snowy)        echo -ne "${P_CYAN}" ;;
    foggy)        echo -ne "${P_DIM}" ;;
    *)            echo -ne "${P_CYAN}" ;;
  esac
}

build_banner() {
  local compact=0
  [[ "$BOOTSTRAP_BANNER" == "compact" ]] && compact=1

  local porquemo_trunc="$PORQUEMO"
  [[ ${#PORQUEMO} -gt $(( compact ? 35 : 50 )) ]] && porquemo_trunc="${PORQUEMO:0:$(( compact ? 32 : 47 ))}..."

  # Data/hora + tempo (cores fosforo)
  local weather_now="${P_CYAN}${DIA}  ${HORA}${R}  ${P_DIM}│${R}  "
  weather_now+="${P_AMBER}${WEATHER_TEMP:-?}°C${R}"
  if [[ $compact -eq 0 ]]; then
    [[ -n "${WEATHER_FEELS:-}" && "${WEATHER_FEELS:-}" != "${WEATHER_TEMP:-}" ]] && \
      weather_now+=" ${P_DIM}(${WEATHER_FEELS}° sens.)${R}"
  fi
  weather_now+="  $(weather_desc_color)${WEATHER_DESC:-?}${R}"
  [[ -n "${WEATHER_HUMIDITY:-}" ]] && weather_now+="  ${P_CYAN}${WEATHER_HUMIDITY}% 💧${R}"
  [[ $compact -eq 0 && -n "${WEATHER_WIND:-}" ]] && weather_now+="  ${P_DIM}🌬 ${WEATHER_WIND} km/h${R}"

  local today_range=""
  [[ -n "${WEATHER_TMIN:-}" ]] && today_range="${P_CYAN}${WEATHER_TMIN}°–${WEATHER_TMAX}°${R}"
  [[ $compact -eq 0 && -n "${WEATHER_SUNRISE:-}" ]] && today_range+="  ${P_AMBER}☀ ${WEATHER_SUNRISE} – ${WEATHER_SUNSET}${R}"

  local today_hours=""
  if [[ $compact -eq 0 ]]; then
    for (( h=0; h<${WEATHER_HOUR_COUNT:-0}; h++ )); do
      local vname="WEATHER_HOUR_${h}"
      [[ -n "$today_hours" ]] && today_hours+="  "
      today_hours+="${P_CYAN}${!vname:-}${R}"
    done
  fi

  local info_lines=()
  if [[ $compact -eq 1 ]]; then
    info_lines=(
      "$weather_now"
      ""
      "${P_DIM}Hoje:${R} ${today_range}"
    )
  else
    local week_lines=()
    for (( w=0; w<${WEATHER_WEEK_COUNT:-0}; w++ )); do
      local vname="WEATHER_WEEK_${w}"
      local line="${!vname:-}"
      [[ -z "${line// }" ]] && continue
      week_lines+=("  ${P_GREEN}${line%% *}${R} ${P_CYAN}${line#* }${R}")
    done
    info_lines=(
      "$weather_now"
      ""
      "${P_DIM}Hoje:${R} ${today_range}"
      "${P_DIM}Horário:${R} ${today_hours}"
    )
    [[ ${#week_lines[@]} -gt 0 ]] && {
      info_lines+=("${P_DIM}Próximos dias:${R}")
      for wl in "${week_lines[@]}"; do info_lines+=("  $wl"); done
    }
  fi

  local total=${#info_lines[@]}
  for (( i=0; i<total; i++ )); do
    echo -e "${info_lines[$i]:-}"
  done
}

build_banner
echo

# --- Workers (systemd oneshot + timer → detect via log age) ---
worker_parts=()
for clock in every10 every60 every240; do
  IFS=: read -r last_mod last_log <<< "$(find_latest_log "$clock")"

  if [[ -z "$last_log" ]]; then
    worker_parts+=("${P_RED}● ${clock}${R} ${P_DIM}--${R}")
  else
    age=$(( now - last_mod ))
    if [[ "$clock" == "every10" ]]; then max=900; elif [[ "$clock" == "every240" ]]; then max=15000; else max=4200; fi

    if [[ $age -le 120 ]]; then
      worker_parts+=("${P_GREEN}● ${clock}${R} ${P_DIM}running${R}")
    elif [[ $age -le $max ]]; then
      worker_parts+=("${P_GREEN}● ${clock}${R} ${P_DIM}$(fmt_age $age)${R}")
    else
      worker_parts+=("${P_AMBER}● ${clock}${R} ${P_DIM}$(fmt_age $age)${R}")
    fi
  fi
done
echo -e "${P_GREEN}Bochechas:${R} ${worker_parts[0]}  ${worker_parts[1]}  ${worker_parts[2]}"
echo

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
git_str="${P_CYAN}[${ws_branch}]${R}"
[[ -n "$ws_dirty" ]] && git_str+=" ${P_AMBER}dirty${R}" || git_str+=" ${P_GREEN}clean${R}"
[[ "$ws_ahead" -gt 0 ]] && git_str+=" ${P_GREEN}↑${ws_ahead}${R}"
[[ "$ws_behind" -gt 0 ]] && git_str+=" ${P_RED}↓${ws_behind}${R}"

MODE_FILE="$WS/projetos/CLAUDE.md"
if [[ -f "$MODE_FILE" ]] && grep -q 'FÉRIAS \[OFF\]' "$MODE_FILE" 2>/dev/null; then
  ferias_str="${P_RED}OFF${R}"
else
  ferias_str="${P_GREEN}ON${R}"
fi
PERSONALITY_FLAG="$WS/.ephemeral/personality-off"
if [[ -f "$PERSONALITY_FLAG" ]]; then
  personality_str="${P_DIM}OFF${R}"
else
  personality_str="${P_CYAN}ON${R}"
fi
AUTOCOMMIT_FLAG="$WS/.ephemeral/auto-commit"
if [[ -f "$AUTOCOMMIT_FLAG" ]]; then
  autocommit_str="${P_GREEN}ON${R}"
else
  autocommit_str="${P_DIM}OFF${R}"
fi
AUTOJARVIS_FLAG="$WS/.ephemeral/auto-jarvis"
if [[ -f "$AUTOJARVIS_FLAG" ]]; then
  autojarvis_str="${P_GREEN}ON${R}"
else
  autojarvis_str="${P_DIM}OFF${R}"
fi
echo -e "${P_CYAN}Git:${R} ${git_str}  ${P_CYAN}Ferias:${R} ${ferias_str}  ${P_CYAN}Personality:${R} ${personality_str}  ${P_CYAN}AutoCommit:${R} ${autocommit_str}  ${P_CYAN}AutoJarvis:${R} ${autojarvis_str}"

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

[[ "$inbox_count" -gt 0 ]] && echo -e "${P_CYAN}Inbox:${R} ${P_AMBER}${inbox_count} pendente(s)${R}"

echo

# --- PRs / repos / worktrees (quando AutoJarvis ON) — alinhado com Bochechas/Git/Inbox ---
if [[ -f "$AUTOJARVIS_FLAG" ]] && command -v gh &>/dev/null; then
  WS="$WS" source "$WS/stow/.claude/scripts/gh-status.sh" 2>/dev/null || true
  [[ -f "${GH_STATUS_CACHE:-}" ]] && source "${GH_STATUS_CACHE}" 2>/dev/null || true
  ( gh_status_fetch 2>/dev/null ) &

  # Max title width: terminal - indent(4) - bullet(2) - repo(16) - spacing(3) - author(~20)
  title_max=$(( COLS - 26 ))
  [[ $title_max -lt 20 ]] && title_max=20

  if [[ -n "${GH_MY_PRS_COUNT:-}" ]]; then
    echo -e "${P_CYAN}PRs meus:${R} ${P_AMBER}${GH_MY_PRS_COUNT}${R} abertos"

    if [[ -n "${GH_MY_PRS:-}" ]]; then
      count=0
      while IFS='|' read -r repo title url; do
        [[ -z "$repo" ]] && continue
        [[ $count -ge 5 ]] && break
        [[ ${#title} -gt $title_max ]] && title="${title:0:$((title_max - 3))}..."
        if [[ -n "$url" ]]; then
          pr_num="${url##*/}"
          printf "  ${P_GREEN}▸${R} ${P_DIM}%-16s${R} %s ${P_DIM}\e]8;;%s\e\\#%s\e]8;;\e\\${R}\n" "$repo" "$title" "$url" "$pr_num"
        else
          printf "  ${P_GREEN}▸${R} ${P_DIM}%-16s${R} %s\n" "$repo" "$title"
        fi
        count=$((count + 1))
      done <<< "$GH_MY_PRS"
    fi

    if [[ -n "${GH_REVIEW_PRS:-}" ]]; then
      echo -e "${P_CYAN}Review:${R} ${P_AMBER}${GH_REVIEW_COUNT}${R} aguardando"
      review_max=$(( title_max - 20 ))  # space for author
      [[ $review_max -lt 20 ]] && review_max=20
      count=0
      while IFS='|' read -r repo title author url; do
        [[ -z "$repo" ]] && continue
        [[ $count -ge 5 ]] && break
        [[ ${#title} -gt $review_max ]] && title="${title:0:$((review_max - 3))}..."
        if [[ -n "$url" ]]; then
          pr_num="${url##*/}"
          printf "  ${P_MAGENTA}◆${R} ${P_DIM}%-16s${R} %s ${P_DIM}(%s) \e]8;;%s\e\\#%s\e]8;;\e\\${R}\n" "$repo" "$title" "$author" "$url" "$pr_num"
        else
          printf "  ${P_MAGENTA}◆${R} ${P_DIM}%-16s${R} %s ${P_DIM}(%s)${R}\n" "$repo" "$title" "$author"
        fi
        count=$((count + 1))
      done <<< "$GH_REVIEW_PRS"
    fi
  else
    echo -e "${P_DIM}(gh indisponível ou sem dados)${R}"
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
    dirty_repos+=("$(printf "  ${P_AMBER}●${R} ${P_DIM}%-16s${R} [%s] ${P_AMBER}dirty:%s${R} ${P_GREEN}ahead:%s${R}" "$name" "$branch" "$dirty" "$ahead")")
  done
  if [[ ${#dirty_repos[@]} -gt 0 ]]; then
    echo -e "${P_CYAN}Repos com mudanças:${R} ${#dirty_repos[@]}"
    for line in "${dirty_repos[@]:0:6}"; do
      echo -e "$line"
    done
    remaining=$(( ${#dirty_repos[@]} - 6 ))
    [[ $remaining -gt 0 ]] && echo -e "  ${P_DIM}+${remaining} mais${R}"
  fi

  prunable=$(git -C "$WS" worktree list 2>/dev/null | grep -c prunable || true)
  active_wt=$(git -C "$WS" worktree list 2>/dev/null | grep -cv "prunable\|$WS " || true)
  [[ $prunable -gt 0 ]] && echo && echo -e "${P_CYAN}Worktrees:${R} ${active_wt} ativos, ${P_AMBER}${prunable} prunable${R} ${P_DIM}(git worktree prune)${R}"

  echo
fi

# --- Conversas GitHub (PRs + issues abertas) ---
conv_lines=$(WS="$WS" CONV_LIMIT=5 bash "$WS/stow/.claude/scripts/recent-conversations.sh" 2>/dev/null || true)
if [[ -n "$conv_lines" ]]; then
  echo -e "${P_CYAN}GitHub abertos:${R}"
  conv_max=$(( COLS - 40 ))
  [[ $conv_max -lt 20 ]] && conv_max=20
  while IFS='|' read -r dt kind repo title url; do
    [[ -z "$dt" ]] && continue
    [[ ${#title} -gt $conv_max ]] && title="${title:0:$((conv_max - 3))}..."
    if [[ "$kind" == "PR" ]]; then
      icon="${P_GREEN}▸${R}"
    else
      icon="${P_AMBER}○${R}"
    fi
    local_num="${url##*/}"
    printf "  ${icon} ${P_DIM}%s${R}  ${P_DIM}%-16s${R} %s ${P_DIM}#%s${R}\n" "$dt" "$repo" "$title" "$local_num"
  done <<< "$conv_lines"
  echo
fi

echo -e "${P_DIM}$(printf '─%.0s' $(seq 1 80))${R}"
echo -e "${P_DIM}Iniciando Claudinho...${R}"
echo

# Quando source/. : retorna; quando executado: exit (evita matar o shell no make start)
[[ "${BASH_SOURCE[0]:-}" != "$0" ]] && return 0 || exit 0
