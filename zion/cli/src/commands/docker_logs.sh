zion_load_config
svc="${args[service]}"
case "$svc" in mono) svc="monolito" ;; bo) svc="bo-container" ;; front|fs) svc="front-student" ;; esac
_zion_dk_logs "$svc" "${args[--follow]:-}" "${args[--tail]:-100}" "${args[--worktree]:-}"
