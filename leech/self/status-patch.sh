# Status agregado: sessão leech + dockerized services + cota
leech_load_config

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

# Env selecionado por servico (usado no start)
declare -A _svc_env
for _s in "${_svc_list[@]}"; do _svc_env[$_s]="sand"; done
_envs_cycle=(sand local prod)

# Cache de env/branch por servico (TTL 30s — evita docker inspect no arrow key)
declare -A _svc_env_label _svc_branch_label _svc_meta_ts

# Feedback de acao (iniciando/parando) — exibido por 15s
declare -A _svc_action _svc_action_ts

# Scroll do painel de logs (linhas acima do fim; 0 = mais recente)
_log_scroll=0

trap 'kill "$_stats_pid" "$_quota_pid" 2>/dev/null; rm -f "$_tmpfile" "$_stats_file" "${_stats_file}.new" "$_quota_file" "${_quota_file}.new"; printf "\033[?1049l\033[?25h"' EXIT
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
  local usage_script="${LEECH_ROOT:-$HOME/nixos/leech/self}/scripts/claude-ai-usage.sh"
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
  local _A_UPTIME_W=5 _A_NAME_W=12

  # ── Coleta paralela: docker ps leech + dk (rápido, ~50ms cada) ──
  local _f_leech _f_dk
  _f_leech=$(mktemp); _f_dk=$(mktemp)

  docker ps -a \
    --filter "ancestor=leech" \
    --filter "name=leech" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" \
    > "$_f_leech" 2>/dev/null &
  local _pid_leech=$!

  docker ps -a --filter "name=leech-dk-" \
    --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" \
    > "$_f_dk" 2>/dev/null &
  local _pid_dk=$!

  # Header enquanto coleta
  echo -e "${BOLD}${MAGENTA}  Leech Status${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}  ${DIM}$(TZ=UTC date '+%H:%M') UTC${RESET}\n"

  # Quota: lê do arquivo de background (instantâneo)
  cat "$_quota_file" 2>/dev/null || true

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
  export _LEECH_SHARED_STATS="$_sess_stats_cache"
  export _LEECH_SHARED_DK_ROWS="$_all_dk_rows"

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
      uptime_raw=$(echo "$status" | sed -E 's/Up //i; s/ \(.*\)//; s/About an hour/~1h/; s/About ([0-9]+) hours?/~\1h/; s/ seconds?/s/; s/ minutes?/min/; s/ hours?/h/; s/ days?/d/')
    else
      icon="${RED}○${RESET}"
      uptime_raw="stopped"
    fi
    local uptime_pad
    uptime_pad=$(printf "%-${_A_UPTIME_W}s" "$uptime_raw")

    local short="${name#leech-projects-leech-run-}"
    short="${short#leech-projects-}"
    local name_pad
    name_pad=$(printf "%-${_A_NAME_W}s" "$short")

    local dest_mounts
    dest_mounts=$(echo "$_inspect_cache" | awk -F'|' -v n="$name" '$1==n {print $3}' | head -1)
    local vols=()
    for v_entry in "/workspace/mnt:mnt" "/workspace/obsidian:obs" "/workspace/self:leech" "/workspace/logs/docker:logs"; do
      local vp="${v_entry%%:*}" vn="${v_entry##*:}"
      if echo "$dest_mounts" | grep -qw "$vp"; then
        vols+=("${GREEN}${vn}${RESET}")
      else
        vols+=("${RED}${vn}${RESET}")
      fi
    done
    local vols_str
    vols_str=$(IFS=' '; echo "${vols[*]}")

    local cpu_str="" mem_str=""
    if echo "$status" | grep -qi "^up"; then
      local raw_stats
      raw_stats=$(echo "$_sess_stats_cache" | awk -F'\t' -v n="$name" '$1==n || $1 ~ n {print $2, $3, $4}' | head -1)
      if [[ -n "$raw_stats" ]]; then
        local cpu mem mem_short
        cpu=$(echo "$raw_stats" | awk '{print $1}')
        mem=$(echo "$raw_stats" | awk '{print $2, $3, $4}')
        mem_short=$(echo "$mem" | sed -E 's/([0-9]+)\.[0-9]+(MiB|GiB)/\1\2/g; s/MiB/M/g; s/GiB/G/g; s/ \/ /\//g')
        cpu_str="${DIM}cpu ${YELLOW}$(printf "%-6s" "$cpu")${RESET}"
        mem_str="${DIM} ${CYAN}${mem_short}${RESET}"
      fi
    fi

    echo -e "${pfx}${icon} ${ORANGE}${uptime_pad}${RESET}  ${WHITE}${name_pad}${RESET}  ${cpu_str}${mem_str}  ${DIM}${vols_str}${RESET}"
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
  }

  echo ""
  _print_agent_group "agents" "$_agent_rows"
  _print_agent_group "background" "$_bg_rows"

  source "$leech_bash_dir/src/lib/docker_status_impl.sh" 2>/dev/null || true
  if declare -f _leech_dk_status >/dev/null 2>&1; then
    _leech_dk_status "" 1
  fi
  echo ""

  # Rodapé interativo
  echo -e "${DIM}──────────────────────────────────────────────────${RESET}"
  local _cenv="${_svc_env[$_cursor_svc]:-sand}"
  echo -e "  ${DIM}↑↓ navegar   ${GREEN}e${RESET}${DIM}[${YELLOW}${_cenv}${RESET}${DIM}]   ${CYAN}s${RESET}${DIM} iniciar   ${RED}S${RESET}${DIM} parar   ${BLUE}l${RESET}${DIM} logs   ${YELLOW}t${RESET}${DIM} test   ${MAGENTA}x${RESET}${DIM} shell   ${DIM}[/]${RESET}${DIM} scroll   [${_cursor_svc}]${RESET}"

  # ── Painel de logs (preenche o restante do terminal) ──────────
  local _term_h; _term_h=$(tput lines 2>/dev/null || echo 40)
  # ~18 linhas fixas: header + quota + agents + services + footer
  local _panel_h=$(( _term_h - 18 ))
  [[ "$_panel_h" -lt 3 ]] && _panel_h=3

  local _log_dir
  if [[ "${CLAUDE_ENV:-}" == "container" ]]; then
    _log_dir="/workspace/logs/docker/${_cursor_svc}"
  else
    _log_dir="${XDG_DATA_HOME:-$HOME/.local/share}/leech/logs/dockerized/${_cursor_svc}"
  fi
  local _log_file="${_log_dir}/service.log"

  # Separador com nome do servico e indicador de scroll
  local _scroll_hint=""
  [[ "$_log_scroll" -gt 0 ]] && _scroll_hint="${YELLOW} +${_log_scroll}↑${RESET}${DIM}"
  echo -e "${DIM}── Logs [${CYAN}${_cursor_svc}${RESET}${DIM}]${_scroll_hint} ────────────────────────────────${RESET}"

  if [[ ! -f "$_log_file" ]]; then
    echo -e "  ${DIM}sem log — ${_log_file}${RESET}"
    return
  fi

  # Lê buffer do log: strip ANSI + CR, filtra linhas vazias
  local -a _log_buf
  mapfile -t _log_buf < <(
    tail -n $(( _panel_h + _log_scroll + 60 )) "$_log_file" 2>/dev/null \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\r//' \
    | grep -v '^[[:space:]]*$'
  )

  local _ltotal="${#_log_buf[@]}"
  local _lend=$(( _ltotal - _log_scroll ))
  [[ "$_lend" -lt 0 ]] && _lend=0
  local _lstart=$(( _lend - _panel_h ))
  [[ "$_lstart" -lt 0 ]] && _lstart=0

  for (( i=_lstart; i<_lend && i<_ltotal; i++ )); do
    local _ln="${_log_buf[$i]}"
    local _lc="$DIM"
    echo "$_ln" | grep -qiE 'error|fatal|crit|panic' && _lc="$RED"
    echo "$_ln" | grep -qiE '\bwarn' && _lc="$YELLOW"
    printf "  ${_lc}%s${RESET}\n" "$_ln"
  done
}

# Alternate screen: posicionamento absoluto, sem tracking de linhas
_render_frame() {
  _do_status_render > "$_tmpfile"
  printf '\033[?25l\033[H'  # esconde cursor, vai pro topo
  while IFS= read -r _line; do
    printf '\r%s\033[K\n' "$_line"
  done < "$_tmpfile"
  printf '\033[J'   # limpa resto da tela
  printf '\033[?25h'
}

_update_header() {
  local _remaining="$1"
  local _ind=""
  for ((i=0; i<_tick; i++)); do
    [[ "$i" -lt "$_remaining" ]] && _ind+="·" || _ind+=" "
  done
  printf '\033[?25l'
  printf '\033[2;1H'  # linha 2, col 1 (sempre o header)
  printf "  ${BOLD}${MAGENTA}Leech Status${RESET}  ${DIM}$(date '+%H:%M:%S')${RESET}  ${DIM}$(TZ=UTC date '+%H:%M') UTC  ${_ind}${RESET}\033[K"
  printf '\033[?25h'
}

# Entrar em alternate screen (preserva conteudo do terminal ao sair)
printf '\033[?1049h\033[H\033[2J'

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
          '[A')  # Up — navega servico, reseta scroll
            _cursor_idx=$(( (_cursor_idx - 1 + ${#_svc_list[@]}) % ${#_svc_list[@]} ))
            _cursor_svc="${_svc_list[$_cursor_idx]}"
            _log_scroll=0
            break
            ;;
          '[B')  # Down — navega servico, reseta scroll
            _cursor_idx=$(( (_cursor_idx + 1) % ${#_svc_list[@]} ))
            _cursor_svc="${_svc_list[$_cursor_idx]}"
            _log_scroll=0
            break
            ;;
          '[5')  # PgUp — scroll log para cima
            read -t 0.1 -rsn1 2>/dev/null || true
            _log_scroll=$(( _log_scroll + 10 ))
            break
            ;;
          '[6')  # PgDn — scroll log para baixo
            read -t 0.1 -rsn1 2>/dev/null || true
            _log_scroll=$(( _log_scroll > 10 ? _log_scroll - 10 : 0 ))
            break
            ;;
        esac
      else
        case "$_key" in
          '[')  # [ scroll log para cima
            _log_scroll=$(( _log_scroll + 5 ))
            break
            ;;
          ']')  # ] scroll log para baixo
            _log_scroll=$(( _log_scroll > 5 ? _log_scroll - 5 : 0 ))
            break
            ;;
          e)
            local _cur_env="${_svc_env[$_cursor_svc]:-sand}"
            local _ei=0
            for _ci in "${!_envs_cycle[@]}"; do
              [[ "${_envs_cycle[$_ci]}" == "$_cur_env" ]] && _ei="$_ci"
            done
            _ei=$(( (_ei + 1) % ${#_envs_cycle[@]} ))
            _svc_env[$_cursor_svc]="${_envs_cycle[$_ei]}"
            break
            ;;
          s)
            leech runner "$_cursor_svc" start --env="${_svc_env[$_cursor_svc]:-sand}" &>/dev/null &
            _svc_action[$_cursor_svc]="iniciando"
            _svc_action_ts[$_cursor_svc]=$(date +%s)
            break
            ;;
          S)
            leech runner "$_cursor_svc" stop &>/dev/null &
            _svc_action[$_cursor_svc]="parando"
            _svc_action_ts[$_cursor_svc]=$(date +%s)
            break
            ;;
          l)
            trap - INT
            printf "\033[2J\033[H"
            leech runner "$_cursor_svc" logs || true
            trap 'exit 0' INT TERM
            printf "\033[2J\033[H"
            break
            ;;
          t)
            trap - INT
            printf "\033[2J\033[H"
            leech runner "$_cursor_svc" test || true
            trap 'exit 0' INT TERM
            printf "\033[2J\033[H"
            break
            ;;
          x)
            trap - INT
            printf "\033[2J\033[H"
            leech runner "$_cursor_svc" shell || true
            trap 'exit 0' INT TERM
            printf "\033[2J\033[H"
            break
            ;;
          q) exit 0 ;;
        esac
      fi
    fi
    _remaining=$((_remaining - 1))
    _update_header "$_remaining"
  done
done
