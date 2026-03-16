mkdir -p "$claudio_nixos_logs"
logfile="$claudio_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[claudio worker-run-fast] Log: $logfile"
OBSIDIAN_PATH="$claudio_obsidian_path" claudio_compose_cmd run --rm \
  -e CLAU_VERBOSE=1 -e CLAU_CLOCK=every10 \
  -e CLAU_WORKER_ID="${CLAU_WORKER_ID:-worker-fast}" \
  worker-fast /workspace/host/scripts/clau-runner.sh 2>&1 | tee "$logfile"
