zion_load_config
svc="${args[service]}"
case "$svc" in mono) svc="monolito" ;; bo) svc="bo-container" ;; front|fs) svc="front-student" ;; esac
_zion_dk_build "$svc" "${args[--worktree]:-}"
