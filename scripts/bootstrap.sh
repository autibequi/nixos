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
ORANGE='\033[38;5;208m' BLUE='\033[38;5;33m' WHITE='\033[97m' MAGENTA='\033[35m'

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

# --- Weather (async, cached 30min) ---
WEATHER_CACHE="$WS/.ephemeral/.weather-cache"
WEATHER_STR=""
if [[ -f "$WEATHER_CACHE" ]]; then
  cache_age=$(( now - $(stat -c %Y "$WEATHER_CACHE" 2>/dev/null || echo 0) ))
  if [[ $cache_age -le 1800 ]]; then
    WEATHER_STR=$(cat "$WEATHER_CACHE")
  fi
fi
if [[ -z "$WEATHER_STR" ]]; then
  WEATHER_STR=$(curl -s --connect-timeout 3 "wttr.in/${WEATHER_LOCATION}?format=%c+%t+%h&lang=pt" 2>/dev/null || echo "")
  WEATHER_STR=$(echo "$WEATHER_STR" | tr -d '+')
  if [[ -n "$WEATHER_STR" && ! "$WEATHER_STR" =~ "Unknown" && ! "$WEATHER_STR" =~ "Sorry" ]]; then
    echo "$WEATHER_STR" > "$WEATHER_CACHE" 2>/dev/null || true
  else
    WEATHER_STR="--"
  fi
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

build_banner_1() {
  echo -e "${WHITE}"
  printf '    ╔'; printf '═%.0s' $(seq 1 $((BOX_W + 2))); echo '╗'
  pad_line "║" ""
  pad_line "║" "${ORANGE}◉${R} ${B}A P E R T U R E${R} ${ORANGE}◉${R}"
  pad_line "║" "${BLUE}  S C I E N C E${R}"
  pad_line "║" ""
  pad_line "║" "${DIM}${DIA}  ${HORA}  ${WEATHER_STR}${R}"
  pad_line "║" ""
  pad_line "║" "${DIM}${PORQUEMO}${R}"
  printf '    ╚'; printf '═%.0s' $(seq 1 $((BOX_W + 2))); echo -e '╝'
  echo -ne "${R}"
}

build_banner_2() {
  echo -e "${WHITE}"
  printf '    ╭'; printf '─%.0s' $(seq 1 $((BOX_W + 2))); echo '╮'
  pad_line "│" ""
  pad_line "│" "${ORANGE}◉${R} ${B}A P E R T U R E${R} ${ORANGE}◉${R}"
  pad_line "│" "${BLUE}  S C I E N C E${R}"
  pad_line "│" ""
  pad_line "│" "${DIM}${DIA}  ${HORA}  ${WEATHER_STR}${R}"
  pad_line "│" ""
  pad_line "│" "${DIM}${PORQUEMO}${R}"
  printf '    ╰'; printf '─%.0s' $(seq 1 $((BOX_W + 2))); echo -e '╯'
  echo -ne "${R}"
}

build_banner_3() {
  echo -e "${WHITE}"
  printf '    ╔'; printf '═%.0s' $(seq 1 $((BOX_W + 2))); echo '╗'
  pad_line "║" ""
  pad_line "║" "${ORANGE}◉${R} ${B}A P E R T U R E  S C I E N C E${R} ${ORANGE}◉${R}"
  pad_line "║" ""
  pad_line "║" "${DIM}${DIA}  ${HORA}  ${WEATHER_STR}${R}"
  pad_line "║" ""
  pad_line "║" "${DIM}${PORQUEMO}${R}"
  printf '    ╚'; printf '═%.0s' $(seq 1 $((BOX_W + 2))); echo -e '╝'
  echo -ne "${R}"
}

BANNER_FUNCS=(build_banner_1 build_banner_2 build_banner_3)

echo
${BANNER_FUNCS[$((RANDOM % ${#BANNER_FUNCS[@]}))]}
echo

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
echo -e "${B}Git:${R} ${git_str}  ${B}Ferias:${R} ${ferias_str}  ${B}Personality:${R} ${personality_str}  ${B}AutoCommit:${R} ${autocommit_str}"

# --- Inbox (coluna do THINKINGS) ---
if [[ -f "$KANBAN" ]]; then
  inbox_count=0; in_inbox=0
  while IFS= read -r line; do
    [[ "$line" == "## Inbox" ]] && { in_inbox=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_inbox" == "1" ]] && break
    [[ "$in_inbox" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && inbox_count=$((inbox_count + 1))
  done < "$KANBAN"
  [[ "$inbox_count" -gt 0 ]] && echo -e "${B}Inbox:${R} ${YELLOW}${inbox_count} pendente(s)${R}"
fi

# --- Esperando Review (itens que precisam da atenção do user) ---
if [[ -f "$KANBAN" ]]; then
  waiting_names=(); waiting_descs=(); in_waiting=0; max_wn=0
  while IFS= read -r line; do
    [[ "$line" == "## Esperando Review" ]] && { in_waiting=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_waiting" == "1" ]] && break
    if [[ "$in_waiting" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
      after="${line#*\*\*}"; name="${after%%\*\**}"
      desc=""; if [[ "$line" == *" — "* ]]; then
        raw="${line##* — }"; [[ ${#raw} -gt 40 ]] && raw="${raw:0:37}..."
        desc="${raw}"
      fi
      waiting_names+=("$name"); waiting_descs+=("$desc")
      [[ ${#name} -gt $max_wn ]] && max_wn=${#name}
    fi
  done < "$KANBAN"
  if [[ ${#waiting_names[@]} -gt 0 ]]; then
    echo -e "${B}${MAGENTA}Esperando review (${#waiting_names[@]}):${R}"
    for i in "${!waiting_names[@]}"; do
      printf "  ${MAGENTA}◆${R} %-${max_wn}s ${DIM}%s${R}\n" "${waiting_names[$i]}" "${waiting_descs[$i]}"
    done
  fi
fi

# Divisória visual
echo -e "${DIM}$(printf '─%.0s' $(seq 1 80))${R}"

# --- THINKINGS (lista unificada) ---
if [[ -f "$KANBAN" ]]; then
  item_prefixes=(); item_names=(); item_descs=(); item_colors=(); max_tn=0

  # Em Andamento → [/]
  in_col=0
  while IFS= read -r line; do
    [[ "$line" == "## Em Andamento" ]] && { in_col=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]] && break
    if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]]; then
      after="${line#*\*\*}"; name="${after%%\*\**}"
      desc=""; if [[ "$line" == *" — "* ]]; then
        raw="${line##* — }"; [[ ${#raw} -gt 40 ]] && raw="${raw:0:37}..."
        desc="${raw}"
      fi
      item_prefixes+=("[/]"); item_names+=("$name"); item_descs+=("$desc"); item_colors+=("$YELLOW")
      [[ ${#name} -gt $max_tn ]] && max_tn=${#name}
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
        raw="${line##* — }"; [[ ${#raw} -gt 40 ]] && raw="${raw:0:37}..."
        desc="${raw}"
      fi
      item_prefixes+=("[ ]"); item_names+=("$name"); item_descs+=("$desc"); item_colors+=("$DIM")
      [[ ${#name} -gt $max_tn ]] && max_tn=${#name}
    fi
  done < "$KANBAN"

  # Aprovado (hoje) → [x]
  in_col=0
  while IFS= read -r line; do
    [[ "$line" == "## Aprovado" ]] && { in_col=1; continue; }
    [[ "$line" =~ ^##\  ]] && [[ "$in_col" == "1" ]] && break
    if [[ "$in_col" == "1" ]] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"$TODAY"* ]]; then
      after="${line#*\*\*}"; name="${after%%\*\**}"
      item_prefixes+=("[x]"); item_names+=("$name"); item_descs+=(""); item_colors+=("$GREEN")
      [[ ${#name} -gt $max_tn ]] && max_tn=${#name}
    fi
  done < "$KANBAN"

  # Build formatted items — show description only (name as fallback)
  items=()
  for i in "${!item_names[@]}"; do
    label="${item_descs[$i]:-${item_names[$i]}}"
    items+=("${item_colors[$i]}${item_prefixes[$i]} ${label}${R}")
  done

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

  # --- Build THINKINGS lines ---
  think_lines=()
  header="${B}THINKINGS:${R} ${DIM}♻${rec}${R}"
  [[ $fail_count -gt 0 ]] && header+=" ${RED}✗${fail_count}${R}"
  think_lines+=("$header")
  count=0
  for item in "${items[@]}"; do
    [[ $count -ge 10 ]] && break
    think_lines+=("  $item")
    count=$((count + 1))
  done
  remaining=$(( ${#items[@]} - count ))
  [[ $remaining -gt 0 ]] && think_lines+=("  ${DIM}+${remaining} mais${R}")

  # --- Build Agentes lines ---
  agent_lines=()
  if [[ ${#agents_list[@]} -gt 0 ]]; then
    agent_lines+=("${B}Agentes:${R}")
    for ag in "${agents_list[@]}"; do
      agent_lines+=("  ${CYAN}▸${R} ${ag}")
    done
  fi

  # --- Build Commands lines (right column, single list in 2 cols, spaced by namespace) ---
  all_cmds=(/meta:manual /meta:propor /nix:add-pkg /nix:stow /nix:clean /nix:remove-pkg /utils:briefing /utils:task /utils:worktree /estrategia:feature /estrategia:review-pr /estrategia:recommit /estrategia:changelog)
  cmd_count=${#all_cmds[@]}
  cmd_half=$(( (cmd_count + 1) / 2 ))  # ceil division
  cmd_lines=()
  cmd_lines+=("${B}Commands:${R}")
  prev_left_ns="" prev_right_ns=""
  for (( j=0; j<cmd_half; j++ )); do
    left_cmd="${all_cmds[$j]}"
    left_ns="${left_cmd%%:*}"  # e.g. /meta
    right_idx=$(( j + cmd_half ))
    right_cmd="" right_ns=""
    if (( right_idx < cmd_count )); then
      right_cmd="${all_cmds[$right_idx]}"
      right_ns="${right_cmd%%:*}"
    fi
    # blank line if namespace changed in either column (collapse consecutive)
    left_changed=$([[ -n "$prev_left_ns" && "$left_ns" != "$prev_left_ns" ]] && echo 1 || echo 0)
    right_changed=$([[ -n "$prev_right_ns" && -n "$right_ns" && "$right_ns" != "$prev_right_ns" ]] && echo 1 || echo 0)
    if [[ -n "$prev_left_ns" ]] && (( left_changed || right_changed )); then
      # only add blank if last entry wasn't already blank
      [[ "${cmd_lines[-1]}" != "" ]] && cmd_lines+=("")
    fi
    if [[ -n "$right_cmd" ]]; then
      cmd_lines+=("$(printf "  ${CYAN}%-20s${R} ${CYAN}%s${R}" "$left_cmd" "$right_cmd")")
    else
      cmd_lines+=("  ${CYAN}${left_cmd}${R}")
    fi
    prev_left_ns="$left_ns"
    [[ -n "$right_ns" ]] && prev_right_ns="$right_ns"
  done

  # --- Side-by-side rendering (Agentes esquerda | Commands direita) ---
  COL_LEFT=25
  total_left=${#agent_lines[@]}
  total_right=${#cmd_lines[@]}
  total_rows=$(( total_left > total_right ? total_left : total_right ))

  for (( i=0; i<total_rows; i++ )); do
    left="${agent_lines[$i]:-}"
    right="${cmd_lines[$i]:-}"

    vlen=$(python3 -c "
import re, unicodedata, sys
s = re.sub(r'\x1b\[[0-9;]*m', '', sys.argv[1])
w = sum(2 if unicodedata.east_asian_width(c) in ('W','F') else 1 for c in s)
print(w)
" "$(echo -ne "$left")")
    pad=$(( COL_LEFT - vlen ))
    [[ $pad -lt 0 ]] && pad=0

    echo -ne "$left"
    printf "%${pad}s" ""
    echo -e "$right"
  done

  # --- THINKINGS (full width, below) ---
  echo
  for tl in "${think_lines[@]}"; do
    echo -e "$tl"
  done
fi

echo

exit 0
