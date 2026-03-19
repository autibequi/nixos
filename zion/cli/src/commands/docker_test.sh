zion_load_config
svc="${args[service]}"
case "$svc" in mono) svc="monolito" ;; bo) svc="bo-container" ;; front|fs) svc="front-student" ;; esac
default_cmd="yarn test"
[[ "$svc" == "monolito" ]] && default_cmd="make test-ldi"
_zion_dk_shell "$svc" "app" "${args[--cmd]:-$default_cmd}" "${args[--worktree]:-}"
