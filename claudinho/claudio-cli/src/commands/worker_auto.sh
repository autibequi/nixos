claudio_load_config
mkdir -p "$claudio_nixos_logs"
logfile="$claudio_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
OBSIDIAN_PATH="$claudio_obsidian_path" claudio_compose_cmd run --rm -T \
  -e CLAU_CLOCK=every60 \
  -e CLAU_WORKER_ID="${CLAU_WORKER_ID:-worker-1}" \
  worker /workspace/host/scripts/clau-runner.sh > "$logfile" 2>&1
