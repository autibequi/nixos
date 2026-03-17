zion_load_config
# Kanban: preferência por vault do repo; fallback Obsidian
kanban_file="${zion_vault_dir}/kanban.md"
[[ -f "$kanban_file" ]] || kanban_file="${zion_obsidian_path}/Work/kanban.md"
[[ -f "$kanban_file" ]] || kanban_file="${zion_obsidian_path}/kanban.md"
if [[ ! -f "$kanban_file" ]]; then
  echo "[zion worker-clau] kanban não encontrado (procurei $zion_vault_dir e $zion_obsidian_path)" >&2
  exit 1
fi
mkdir -p "$zion_nixos_logs"
logfile="$zion_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[zion worker-clau] Log: $logfile"
for i in 1 2; do
  WORKER_ID="worker-$i"
  existing=$(docker ps --filter "name=_worker_" --filter "label=clau.worker.id=$WORKER_ID" --format "{{.ID}}" 2>/dev/null | head -1)
  if [[ -n "$existing" ]]; then
    echo "[zion worker-clau] $WORKER_ID já rodando ($existing) — skip"
    continue
  fi
  echo "[zion worker-clau] Lançando $WORKER_ID (every60)..."
  OBSIDIAN_PATH="$zion_obsidian_path" zion_compose_cmd run --rm -T \
    -e SCHEDULER_WORKER_ID="$WORKER_ID" \
    -e SCHEDULER_CLOCK=every60 \
    -l "clau.worker.id=$WORKER_ID" \
    worker /zion/scripts/puppy-runner.sh >> "$logfile" 2>&1 &
done
echo "[zion worker-clau] Workers lançados. Seguindo log..."
tail -f "$logfile"
