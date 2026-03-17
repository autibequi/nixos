mkdir -p "$zion_nixos_logs"
logfile="$zion_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
echo "[zion worker-run-fast] Log: $logfile"
OBSIDIAN_PATH="$zion_obsidian_path" zion_compose_cmd run --rm \
  -e SCHEDULER_VERBOSE=1 -e SCHEDULER_CLOCK=every10 \
  -e SCHEDULER_WORKER_ID="${SCHEDULER_WORKER_ID:-worker-fast}" \
  worker-fast /host/zion/scripts/clau-runner.sh 2>&1 | tee "$logfile"
