# Resolve aliases de servico
svc="${args[service]}"
case "$svc" in
  mono) svc="monolito" ;;
  bo)   svc="bo-container" ;;
  front|fs) svc="front-student" ;;
esac

_env="${args[--env]:-sand}"
_worktree="${args[--worktree]:-}"
_vertical="${args[--vertical]:-carreiras-juridicas}"
_container="${args[--container]:-app}"
_cmd="${args[--cmd]:-}"
_tail="${args[--tail]:-100}"
_debug="${args[--debug]:-}"

case "${args[action]}" in
  start)
    _leech_dk_run "$svc" "$_env" "$_debug" "$_worktree" "$_vertical" "1"
    ;;
  stop)
    _leech_dk_stop "$svc" "$_worktree"
    ;;
  logs)
    _leech_dk_logs "$svc" "1" "$_tail" "$_worktree"
    ;;
  test)
    if [[ -z "$_cmd" ]]; then
      case "$svc" in
        monolito) _cmd="make test" ;;
        *)        _cmd="yarn test" ;;
      esac
    fi
    _leech_dk_shell "$svc" "app" "$_cmd" "$_worktree"
    ;;
  shell)
    _leech_dk_shell "$svc" "$_container" "$_cmd" "$_worktree"
    ;;
  install)
    _leech_dk_install "$svc" "$_env" "$_worktree"
    ;;
  build)
    _leech_dk_build "$svc" "$_worktree"
    ;;
  flush)
    _leech_dk_flush "$svc" "$_worktree"
    ;;
esac
