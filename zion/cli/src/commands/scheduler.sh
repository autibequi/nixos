# Sobe/para/status do container scheduler (tick a cada 10 min). Usa -p clau-workers como no systemd.
zion_load_config

SCHEDULER_PROJECT="${SCHEDULER_PROJECT:-clau-workers}"
action="${args[action]:-start}"

scheduler_cmd() {
  zion_compose_cmd -p "$SCHEDULER_PROJECT" "$@"
}

case "$action" in
  start)
    if ! docker network inspect nixos_default &>/dev/null; then
      echo "[zion scheduler] Criando rede nixos_default..."
      docker network create nixos_default 2>/dev/null || true
    fi
    OBSIDIAN_PATH="$zion_obsidian_path" scheduler_cmd up -d scheduler
    echo "[zion scheduler] Container scheduler iniciado (tick a cada 10 min)."
    ;;
  stop)
    OBSIDIAN_PATH="$zion_obsidian_path" scheduler_cmd stop scheduler
    echo "[zion scheduler] Container scheduler parado."
    ;;
  status)
    OBSIDIAN_PATH="$zion_obsidian_path" scheduler_cmd ps scheduler 2>/dev/null || \
      docker ps --filter "label=com.docker.compose.service=scheduler" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || \
      echo "Nenhum container scheduler rodando."
    ;;
  logs)
    OBSIDIAN_PATH="$zion_obsidian_path" scheduler_cmd logs -f scheduler
    ;;
  run-now)
    # Um tick na hora, em foreground — para testar: scheduler escolhe tasks e roda worker com output
    # O worker é um container separado; ele precisa do mesmo OBSIDIAN_PATH (mount em /obsidian)
    export SCHEDULER_PROJECT_DIR="$zion_nixos_dir"
    export SCHEDULER_VAULT_DIR="$zion_obsidian_path"
    export OBSIDIAN_PATH="$zion_obsidian_path"
    export SCHEDULER_COMPOSE_BIN="docker compose"
    export SCHEDULER_COMPOSE_FILES="-f $zion_compose_file -p $SCHEDULER_PROJECT"
    echo "[zion scheduler] Rodando 1 tick agora (scheduler + worker em foreground)..."
    echo "[zion scheduler] Constantes (antes de rodar):"
    echo "  SCHEDULER_PROJECT_DIR=$SCHEDULER_PROJECT_DIR"
    echo "  SCHEDULER_VAULT_DIR=$SCHEDULER_VAULT_DIR"
    echo "  OBSIDIAN_PATH=$OBSIDIAN_PATH"
    echo "  SCHEDULER_COMPOSE_BIN=$SCHEDULER_COMPOSE_BIN"
    echo "  SCHEDULER_COMPOSE_FILES=$SCHEDULER_COMPOSE_FILES"
    echo "  zion_compose_file=$zion_compose_file"
    echo "  SCHEDULER_PROJECT=$SCHEDULER_PROJECT"
    if [[ -d "$OBSIDIAN_PATH/_agent/tasks/recurring" ]]; then
      echo "  _agent/tasks/recurring: existe ($(ls -1 "$OBSIDIAN_PATH/_agent/tasks/recurring" 2>/dev/null | wc -l) pastas)"
    else
      echo "  _agent/tasks/recurring: NÃO EXISTE em $OBSIDIAN_PATH — worker verá 0 tasks." >&2
    fi
    "$zion_nixos_dir/scripts/clau-scheduler.sh"
    ;;
  shell)
    # Entra no shell do container scheduler (precisa estar rodando)
    OBSIDIAN_PATH="$zion_obsidian_path" scheduler_cmd exec -it scheduler /bin/bash
    ;;
  *)
    echo "claudio scheduler: action inválida '$action'. Use: start | stop | status | logs | run-now | shell" >&2
    exit 1
    ;;
esac
