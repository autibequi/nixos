claudio_load_config
# Kanban: preferência por vault do repo; fallback Obsidian
kanban_file="${claudio_vault_dir}/kanban.md"
[[ -f "$kanban_file" ]] || kanban_file="${claudio_obsidian_path}/Work/kanban.md"
[[ -f "$kanban_file" ]] || kanban_file="${claudio_obsidian_path}/kanban.md"
if [[ ! -f "$kanban_file" ]]; then
  echo "[claudio worker-clau] kanban não encontrado (procurei $claudio_vault_dir e $claudio_obsidian_path)" >&2
  exit 1
fi
mkdir -p "$claudio_nixos_logs"
logfile="$claudio_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[claudio worker-clau] Log: $logfile"
for i in 1 2; do
  WORKER_ID="worker-$i"
  existing=$(docker ps --filter "name=_worker_" --filter "label=clau.worker.id=$WORKER_ID" --format "{{.ID}}" 2>/dev/null | head -1)
  if [[ -n "$existing" ]]; then
    echo "[claudio worker-clau] $WORKER_ID já rodando ($existing) — skip"
    continue
  fi
  echo "[claudio worker-clau] Lançando $WORKER_ID (every60)..."
  OBSIDIAN_PATH="$claudio_obsidian_path" claudio_compose_cmd run --rm -T \
    -e CLAU_WORKER_ID="$WORKER_ID" \
    -e CLAU_CLOCK=every60 \
    -l "clau.worker.id=$WORKER_ID" \
    worker /workspace/host/scripts/clau-runner.sh >> "$logfile" 2>&1 &
done
echo "[claudio worker-clau] Workers lançados. Seguindo log..."
tail -f "$logfile"
