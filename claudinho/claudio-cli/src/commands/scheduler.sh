# Sobe/para/status do container scheduler (tick a cada 10 min). Usa -p clau-workers como no systemd.
claudio_load_config

CLAU_PROJECT="${CLAU_PROJECT:-clau-workers}"
action="${args[action]:-start}"

scheduler_cmd() {
  claudio_compose_cmd -p "$CLAU_PROJECT" "$@"
}

case "$action" in
  start)
    if ! docker network inspect nixos_default &>/dev/null; then
      echo "[claudio scheduler] Criando rede nixos_default..."
      docker network create nixos_default 2>/dev/null || true
    fi
    OBSIDIAN_PATH="$claudio_obsidian_path" scheduler_cmd up -d scheduler
    echo "[claudio scheduler] Container scheduler iniciado (tick a cada 10 min)."
    ;;
  stop)
    OBSIDIAN_PATH="$claudio_obsidian_path" scheduler_cmd stop scheduler
    echo "[claudio scheduler] Container scheduler parado."
    ;;
  status)
    OBSIDIAN_PATH="$claudio_obsidian_path" scheduler_cmd ps scheduler 2>/dev/null || \
      docker ps --filter "label=com.docker.compose.service=scheduler" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || \
      echo "Nenhum container scheduler rodando."
    ;;
  logs)
    OBSIDIAN_PATH="$claudio_obsidian_path" scheduler_cmd logs -f scheduler
    ;;
  *)
    echo "claudio scheduler: action inválida '$action'. Use: start | stop | status | logs" >&2
    exit 1
    ;;
esac
