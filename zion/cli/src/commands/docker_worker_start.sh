zion_load_config
svc="${args[service]:-monolito}"
case "$svc" in mono) svc="monolito" ;; esac
_zion_dk_run "${svc}-worker" "${args[--env]:-sand}" "${args[--debug]:-}" "${args[--worktree]:-}" "" "${args[--detach]:-}"
