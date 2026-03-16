# Worker every60; task= opcional; --engine= opcional (repasse ao runner se precisar)
claudio_load_config
engine=$(claudio_resolve_engine 0)
mkdir -p "$claudio_nixos_logs"
logfile="$claudio_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[claudio worker] Log: $logfile"
OBSIDIAN_PATH="$claudio_obsidian_path" \
  CLAU_ENGINE="${engine:-}" \
  claudio_compose_cmd run --rm \
  -e CLAU_VERBOSE=1 -e CLAU_CLOCK=every60 \
  -e CLAU_WORKER_ID="${CLAU_WORKER_ID:-worker-1}" \
  -e CLAU_ENGINE="${engine:-}" \
  worker /workspace/host/scripts/clau-runner.sh ${args[task]:-} 2>&1 | tee "$logfile"
