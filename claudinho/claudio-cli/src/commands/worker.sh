# Worker every60; task= opcional; --engine= opcional (repasse ao runner se precisar)
claudio_load_config
engine=$(claudio_resolve_engine 0)
mkdir -p "$claudio_nixos_logs"
logfile="$claudio_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[claudio worker] Log: $logfile"
OBSIDIAN_PATH="$claudio_obsidian_path" \
  SCHEDULER_ENGINE="${engine:-}" \
  claudio_compose_cmd run --rm \
  -e SCHEDULER_VERBOSE=1 -e SCHEDULER_CLOCK=every60 \
  -e SCHEDULER_WORKER_ID="${SCHEDULER_WORKER_ID:-worker-1}" \
  -e SCHEDULER_ENGINE="${engine:-}" \
  worker /host/claudinho/scripts/clau-runner.sh ${args[task]:-} 2>&1 | tee "$logfile"
