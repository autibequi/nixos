zion_load_config
svc="${args[service]:-monolito}"
case "$svc" in mono) svc="monolito" ;; esac
_zion_dk_stop "${svc}-worker" "${args[--worktree]:-}"
