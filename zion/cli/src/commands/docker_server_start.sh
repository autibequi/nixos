zion_load_config
svc="${args[service]}"
case "$svc" in mono) svc="monolito" ;; bo) svc="bo-container" ;; front|fs) svc="front-student" ;; esac
_zion_dk_run "$svc" "${args[--env]:-sand}" "${args[--debug]:-}" "${args[--worktree]:-}" "${args[--vertical]:-carreiras-juridicas}" "${args[--detach]:-}"
