_zion_dk_logs \
  "${args[service]}" \
  "${args[--follow]:-}" \
  "${args[--tail]:-100}" \
  "${args[--worktree]:-}"
