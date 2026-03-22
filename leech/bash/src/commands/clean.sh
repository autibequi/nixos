# Remove sessões Leech paradas/exited e containers órfãos
leech_load_config

force="${args[--force]:-}"

echo "=== Containers Leech parados ==="
stopped=$(docker ps -a --filter "name=leech-" --filter "status=exited" --format "{{.Names}}" 2>/dev/null)
if [ -z "$stopped" ]; then
  echo "  Nenhum."
else
  echo "$stopped"
  if [ -n "$force" ]; then
    echo "$stopped" | xargs docker rm 2>/dev/null || true
    echo "  Removidos."
  else
    echo "  Use --force para remover."
  fi
fi

echo ""
echo "=== Containers órfãos (criados pelo compose mas sem projeto) ==="
docker compose -f "${LEECH_ROOT:-$HOME/nixos/leech/self}/container/docker-compose.leech.yml" \
  ps --all 2>/dev/null | grep -v "NAME" | grep -v "running" || echo "  Nenhum."
