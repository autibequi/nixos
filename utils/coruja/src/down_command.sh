# down — derruba a stack.

if [[ -n "${args[--volumes]:-}" ]]; then
  echo "derrubando + APAGANDO volumes (pgdata, caches go)..."
  run_compose down -v
else
  run_compose down
fi
