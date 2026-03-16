latest=$(ls -1t "$claudio_nixos_logs"/*.log 2>/dev/null | head -1)
if [[ -z "$latest" ]]; then
  echo "(nenhum log)"
else
  id=$(docker ps --filter "name=_worker_" --format "{{.ID}}" 2>/dev/null | head -1)
  if [[ -n "$id" ]]; then
    echo "=== Seguindo $latest ==="
    tail -f "$latest"
  else
    echo "=== $latest ==="
    cat "$latest"
  fi
fi
