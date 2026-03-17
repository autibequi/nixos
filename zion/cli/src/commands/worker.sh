# Worker every60; task= opcional; --engine= opcional (repasse ao runner se precisar)
zion_load_config
engine=$(zion_resolve_engine 0)
mkdir -p "$zion_nixos_logs"
logfile="$zion_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[zion worker] Log: $logfile"
OBSIDIAN_PATH="$zion_obsidian_path" \
  SCHEDULER_ENGINE="${engine:-}" \
  zion_compose_cmd run --rm \
  -e SCHEDULER_VERBOSE=1 -e SCHEDULER_CLOCK=every60 \
  -e SCHEDULER_WORKER_ID="${SCHEDULER_WORKER_ID:-worker-1}" \
  -e SCHEDULER_ENGINE="${engine:-}" \
  worker /zion/scripts/clau-runner.sh ${args[task]:-} 2>&1 | tee "$logfile"
