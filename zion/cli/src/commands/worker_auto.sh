zion_load_config
mkdir -p "$zion_nixos_logs"
logfile="$zion_nixos_logs/$(date +%Y-%m-%dT%H:%M:%S.%3N).log"
OBSIDIAN_PATH="$zion_obsidian_path" zion_compose_cmd run --rm -T \
  -e SCHEDULER_CLOCK=every60 \
  -e SCHEDULER_WORKER_ID="${SCHEDULER_WORKER_ID:-worker-1}" \
  worker /zion/scripts/puppy-runner.sh > "$logfile" 2>&1
