# Status agregado: sessão zion + dockerized services + cota
zion_load_config

local RESET='\033[0m'
local BOLD='\033[1m'
local DIM='\033[2m'
local GREEN='\033[32m'
local RED='\033[31m'
local YELLOW='\033[33m'
local CYAN='\033[36m'
local MAGENTA='\033[35m'
local ORANGE='\033[38;5;214m'
local WHITE='\033[37m'
local BLUE='\033[34m'

local _tick="${args[--tick]:-5}"
local _tmpfile _stats_file _quota_file
_tmpfile=$(mktemp); _stats_file=$(mktemp); _quota_file=$(mktemp)

# Cursor interativo: lista de servicos navegaveis
_svc_list=(monolito bo-container front-student)
_cursor_idx=0
_cursor_svc="${_svc_list[0]}"

trap 'kill "$_stats_pid" "$_quota_pid" 2>/dev/null; rm -f "$_tmpfile" "$_stats_file" "${_stats_file}.new" "$_quota_file" "${_quota_file}.new"; printf "\033[?25h\n"' EXIT
trap 'exit 0' INT TERM

# ── Background: stats CPU/mem (atualiza a cada 5s) ────────────
_run_stats_bg() {
  while true; do
    docker stats --no-stream \
      --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
      > "${_stats_file}.new" 2>/dev/null \
      && mv "${_stats_file}.new" "$_stats_file" || true
    sleep 5
  done
}
_run_stats_bg &
local _stats_pid=$!

# ── Background: quota Claude (atualiza a cada 60s) ────────────
_run_quota_bg() {
  local usage_script="${ZION_ROOT:-$HOME/nixos/zion}/scripts/claude-ai-usage.sh"
  while true; do
    { [ -x "$usage_script" ] && "$usage_script" 2>/dev/null | tail -2 | sed 's/^/  /' || true; } \
      > "${_quota_file}.new" 2>/dev/null \
      && mv "${_quota_file}.new" "$_quota_file" || true
    sleep 60
  done
}
_run_quota_bg &
local _quota_pid=$!

_do_status_render() {
  local _A_UPTIME_W=7 _A_NAME_W=16 _A_PORTS_W=18

  # ── Coleta paralela: docker ps leech + dk (rápido, ~50ms cada) ──
  local _f_leech _f_dk
  _f_leech=$(mktemp); _f_dk=$(mktemp)

  docker ps -a \
    --filter "ancestor=claude-nix-sandbox" \
    --filter "name=leech" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" \
    > "$_f_leech" 2>/dev/null &
  local _pid_leech=$!

  docker ps -a --filter "name=zion-dk-" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" \
    > "$_f_dk" 2>/dev/null &
  local _pid_dk=$!

  # Header enquanto coleta
  echo -e "\n${BOLD}${MAGENTA}  Zion Status${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}\n"

  # Quota: lê do arquivo de background (instantâneo)
  cat "$_quota_file" 2>/dev/null || true
  echo ""

  if ! docker info >/dev/null 2>&1; then
    echo -e "  ${RED}sem acesso ao Docker${RESET}\n"
    wait "$_pid_leech" "$_pid_dk"; rm -f "$_f_leech" "$_f_dk"
    return
  fi

  wait "$_pid_leech" "$_pid_dk"

  local _all_leech_rows _all_dk_rows
  _all_leech_rows=$(sort -u "$_f_leech" | grep -v "^$" || true)
  _all_dk_rows=$(cat "$_f_dk")
  rm -f "$_f_leech" "$_f_dk"

  # Stats: lê do arquivo de background (instantâneo)
  local _sess_stats_cache
  _sess_stats_cache=$(cat "$_stats_file" 2>/dev/null || true)
  export _ZION_SHARED_STATS="$_sess_stats_cache"
  export _ZION_SHARED_DK_ROWS="$_all_dk_rows"

  # ── Batch docker inspect: TTY + mounts num único request ─────
  local _leech_names=()
  while IFS=$'\t' read -r _cn _ _; do
    [[ -n "$_cn" ]] && _leech_names+=("$_cn")
  done <<< "$_all_leech_rows"

  local _inspect_cache=""
  if [[ "${#_leech_names[@]}" -gt 0 ]]; then
    _inspect_cache=$(docker inspect \
      --format '{{.Name}}|{{.Config.Tty}}|{{range .Mounts}}{{.Destination}} {{end}}' \
      "${_leech_names[@]}" 2>/dev/null | sed 's|^/||')
  fi

  # Separa interactive (TTY=true) de background (TTY=false)
  local _agent_rows="" _bg_rows=""
  while IFS=$'\t' read -r _cn _cs _cp; do
    [[ -z "$_cn" ]] && continue
    local _tty
    _tty=$(echo "$_inspect_cache" | awk -F'|' -v n="$_cn" '$1==n {print $2}' | head -1)
    [[ -z "$_tty" ]] && _tty="true"
    if [[ "$_tty" == "true" ]]; then
      _agent_rows+="${_cn}"$'\t'"${_cs}"$'\t'"${_cp}"$'\n'
    else
      _bg_rows+="${_cn}"$'\t'"${_cs}"$'\t'"${_cp}"$'\n'
    fi
  done <<< "$_all_leech_rows"

  _print_agent_row() {
    local pfx="$1" name="$2" status="$3" tc="${4:-└─}"
    local icon uptime_raw
    if echo "$status" | grep -qi "^up"; then
      icon="${GREEN}●${RESET}"
      uptime_raw=$(echo "$status" | sed -E 's/Up //i; s/ \(.*\)//; s/ seconds?/s/; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/')
    else
      icon="${RED}○${RESET}"
      uptime_raw="stopped"
    fi
    local uptime_pad
    uptime_pad=$(printf "%-${_A_UPTIME_W}s" "$uptime_raw")

    local short="${name#zion-projects-leech-run-}"
    short="${short#zion-projects-}"
    local name_pad
    name_pad=$(printf "%-${_A_NAME_W}s" "$short")

    local cpu_str="" mem_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(echo "$_sess_stats_cache" | awk -F'\t' -v n="$name" '$1==n || $1 ~ n {print $2, $3, $4}' | head -1)
      if [[ -n "$raw_stats" ]]; then
        local cpu mem
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        cpu_str="${DIM}cpu ${YELLOW}$(printf "%-7s" "$cpu")${RESET}"
        mem_str="${DIM}  mem ${CYAN}${mem}${RESET}"
      fi
    fi

    local ports_pad
    ports_pad=$(printf "%-${_A_PORTS_W}s" "")

    echo -e "${pfx}${icon} ${ORANGE}${uptime_pad}${RESET}  ${WHITE}${name_pad}${RESET}  ${DIM}${ports_pad}${RESET}  ${cpu_str}${mem_str}"

    local dest_mounts
    dest_mounts=$(echo "$_inspect_cache" | awk -F'|' -v n="$name" '$1==n {print $3}' | head -1)
    local vols=()
    for v_entry in "/workspace/mnt:mnt" "/workspace/obsidian:obs" "/workspace/zion:zion" "/workspace/logs/docker:logs"; do
      local vp="${v_entry%%:*}" vn="${v_entry##*:}"
      if echo "$dest_mounts" | grep -qw "$vp"; then
        vols+=("${GREEN}${vn}${RESET}")
      else
        vols+=("${RED}${vn}${RESET}")
      fi
    done
    local cont_indent
    [[ "$tc" == "├─" ]] && cont_indent="  ${BLUE}│${RESET}    " || cont_indent="       "
    echo -e "${cont_indent}${DIM}$(IFS='  '; echo "${vols[*]}")${RESET}"
  }

  _print_agent_group() {
    local label="$1" rows="$2"
    local arr=()
    while IFS= read -r line; do [[ -n "$line" ]] && arr+=("$line"); done <<< "$rows"
    local n="${#arr[@]}"
    [[ "$n" -eq 0 ]] && return

    local any_up=0
    echo "$rows" | awk -F'\t' '$2 ~ /^[Uu]p /{found=1} END{exit !found}' && any_up=1
    local grp_icon; [[ "$any_up" -eq 1 ]] && grp_icon="${GREEN}●${RESET}" || grp_icon="${RED}○${RESET}"
    echo -e "${grp_icon} ${BOLD}${CYAN}${label}${RESET}"
    for i in "${!arr[@]}"; do
      IFS=$'\t' read -r _cn _cs _cp <<< "${arr[$i]}"
      local tc="├─"; [[ "$i" -eq "$((n - 1))" ]] && tc="└─"
      _print_agent_row "  ${BLUE}${tc}${RESET} " "$_cn" "$_cs" "$tc"
    done
    echo ""
  }

  _print_agent_group "agents" "$_agent_rows"
  _print_agent_group "background" "$_bg_rows"

  source "${ZION_ROOT:-$HOME/nixos/zion}/cli/src/lib/docker_status_impl.sh" 2>/dev/null || true
  if declare -f _zion_dk_status >/dev/null 2>&1; then
    _zion_dk_status "" 1
  fi
  echo ""

  # Rodapé interativo
  echo -e "${DIM}──────────────────────────────────────────────────${RESET}"
  echo -e "  ${DIM}↑↓ navegar   ${CYAN}s${RESET}${DIM} iniciar   ${RED}S${RESET}${DIM} parar   ${BLUE}l${RESET}${DIM} logs   ${YELLOW}t${RESET}${DIM} test   [${_cursor_svc}]${RESET}"
}

local _lines=0

_render_frame() {
  _do_status_render > "$_tmpfile"
  local _new_lines
  _new_lines=$(wc -l < "$_tmpfile")

  printf '\033[?25l'  # esconde cursor durante rendering
  [[ "$_lines" -gt 0 ]] && printf "\033[%dA" "$_lines"
  printf "\r"

  while IFS= read -r _line; do
    printf '\r%s\033[K\n' "$_line"
  done < "$_tmpfile"

  local _diff=$((_lines - _new_lines))
  for ((i=0; i<_diff; i++)); do printf '\033[2K\n'; done
  [[ "$_diff" -gt 0 ]] && printf "\033[%dA" "$_diff"

  _lines=$_new_lines
  printf '\033[?25h'  # restaura cursor
}

_update_header() {
  local _remaining="$1"
  # Monta indicador de dots que "drena" conforme o tempo passa
  local _ind=""
  for ((i=0; i<_tick; i++)); do
    [[ "$i" -lt "$_remaining" ]] && _ind+="·" || _ind+=" "
  done
  # Header está na linha 2 do bloco; cursor está abaixo de _lines linhas
  # Para chegar na linha 2: subir (_lines - 1) linhas
  printf '\033[?25l'
  printf "\033[%dA\r" "$((_lines - 1))"
  printf "  ${BOLD}${MAGENTA}Zion Status${RESET}  ${DIM}$(date '+%H:%M:%S')  ${_ind}${RESET}\033[K"
  printf "\033[%dB\r" "$((_lines - 1))"
  printf '\033[?25h'
}

while true; do
  _render_frame

  local _remaining="$_tick"
  while [[ "$_remaining" -gt 0 ]]; do
    local _key=""
    if read -t 1 -rsn1 _key 2>/dev/null; then
      if [[ "$_key" == $'\033' ]]; then
        # Sequencia de escape (setas)
        local _seq=""
        read -t 0.1 -rsn2 _seq 2>/dev/null || true
        case "$_seq" in
          '[A')  # Up
            _cursor_idx=$(( (_cursor_idx - 1 + ${#_svc_list[@]}) % ${#_svc_list[@]} ))
            _cursor_svc="${_svc_list[$_cursor_idx]}"
            break
            ;;
          '[B')  # Down
            _cursor_idx=$(( (_cursor_idx + 1) % ${#_svc_list[@]} ))
            _cursor_svc="${_svc_list[$_cursor_idx]}"
            break
            ;;
        esac
      else
        case "$_key" in
          s)
            zion docker "$_cursor_svc" start &>/dev/null &
            ;;
          S)
            zion docker "$_cursor_svc" stop &>/dev/null &
            ;;
          l)
            trap '' INT
            printf "\033[2J\033[H"
            zion docker "$_cursor_svc" logs || true
            trap 'exit 0' INT TERM
            printf "\033[2J\033[H"  # limpa tela antes de voltar ao TUI
            _lines=0; break
            ;;
          t)
            trap '' INT
            printf "\033[2J\033[H"
            zion docker "$_cursor_svc" test || true
            trap 'exit 0' INT TERM
            printf "\033[2J\033[H"  # limpa tela antes de voltar ao TUI
            _lines=0; break
            ;;
          q) exit 0 ;;
        esac
      fi
    fi
    _remaining=$((_remaining - 1))
    _update_header "$_remaining"
  done
done
