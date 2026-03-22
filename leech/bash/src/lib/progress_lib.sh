# progress_lib.sh — helper de progresso compartilhado entre os docker impl
#
# _zion_step <n> <total> <label> <cmd> [args...]
#   Roda <cmd> em background com spinner. Suprime stdout/stderr.
#   Em caso de falha, imprime o log e retorna 1.
#
# _zion_header <title> [subtitle]
#   Imprime cabeçalho padronizado.

_zion_header() {
  local title="$1"
  local sub="${2:-}"
  printf "\n\033[1m%s\033[0m" "$title"
  [[ -n "$sub" ]] && printf "  \033[2m%s\033[0m" "$sub"
  printf "\n"
}

_zion_step() {
  local n="$1"
  local total="$2"
  local label="$3"
  shift 3

  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local idx=0

  "$@" >"$_zion_step_log" 2>&1 &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[33m%s\033[0m" \
      "$n" "$total" "$label" "${frames[$idx]}"
    idx=$(( (idx + 1) % 10 ))
    sleep 0.08
  done

  wait "$pid"
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[32m✓\033[0m\n" "$n" "$total" "$label"
  else
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[31m✗\033[0m\n" "$n" "$total" "$label"
    [[ -s "$_zion_step_log" ]] && cat "$_zion_step_log" >&2
    return 1
  fi
}

_zion_progress_init() {
  _zion_step_log="$(mktemp /tmp/zion-progress-XXXXXX.log)"
  trap 'rm -f "$_zion_step_log"' EXIT
}

_zion_done() {
  printf "  \033[32m\033[1mFeito!\033[0m\n\n"
}
