zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

echo "=== Puppy Container ==="
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" ps 2>/dev/null || \
  echo "  nenhum container rodando"

echo ""
echo "=== Tasks em doing/ ==="
vault="${zion_obsidian_path}/tasks/doing"
if [ -d "$vault" ] && [ -n "$(ls -A "$vault" 2>/dev/null)" ]; then
  for d in "$vault"/*/; do
    [ -d "$d" ] || continue
    echo "  $(basename "$d")"
  done
else
  echo "  nenhuma"
fi

echo ""
echo "=== Scheduled ==="
sched="${zion_obsidian_path}/tasks/_scheduled"
if [ -d "$sched" ]; then
  count=$(ls -d "$sched"/*/ 2>/dev/null | wc -l)
  echo "  $count tasks em _scheduled/"
else
  echo "  sem _scheduled/"
fi
