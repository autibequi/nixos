# down — derruba a stack.

autodown_cancel  # cancela um auto-down pendente (não re-disparar)

if [[ -n "${args[--volumes]:-}" ]]; then
  echo "derrubando + APAGANDO volumes (pgdata, caches go)..."
  run_compose down -v
else
  run_compose down
fi
