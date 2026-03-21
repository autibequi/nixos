# docker_flush_impl.sh — remove tudo relacionado a um servico Docker:
# containers, imagens, volumes, logs, vendor.
#
# Uso: _zion_dk_flush <service> <worktree>

_zion_dk_flush() {
  local service="$1"
  local worktree="${2:-}"

  zion_docker_validate_service "$service" || return 1
  zion_docker_init_worktree "$service" "$worktree" || return 1

  local dir config_dir compose deps_compose project log_dir
  dir=$(zion_docker_effective_dir "$service")
  config_dir=$(zion_docker_config_dir "$service")
  compose=$(zion_docker_compose_file "$service")
  deps_compose=$(zion_docker_deps_file "$service")
  project=$(zion_docker_effective_project "$service")
  log_dir=$(zion_docker_log_dir "$service")
  [[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"

  local local_label="$service"
  [[ -n "$_ZION_DK_WORKTREE" ]] && local_label="$service (wt: $_ZION_DK_WORKTREE)"

  _zion_progress_init

  local total=5
  local has_vendor=0
  [[ -d "$dir/vendor" ]] && has_vendor=1 && total=6

  _zion_header "docker flush  $local_label"

  _flush_logger() {
    if [[ -f "$log_dir/logger.pid" ]]; then
      kill "$(cat "$log_dir/logger.pid")" 2>/dev/null || true
      rm -f "$log_dir/logger.pid"
    fi
  }

  _flush_containers() {
    docker compose -f "$compose" -p "$project" down -v --remove-orphans 2>/dev/null || true
    docker compose -p "${project}-deps" down -v --remove-orphans 2>/dev/null || true
  }

  _flush_images() {
    docker images --filter "label=com.docker.compose.project=$project" -q \
      | xargs docker rmi -f 2>/dev/null || true
    docker rmi -f "zion-dk-${service}-app" "zion-dk-${service}-worker" 2>/dev/null || true
  }

  _flush_volumes() {
    docker volume ls --filter "label=com.docker.compose.project=$project" -q \
      | xargs docker volume rm 2>/dev/null || true
  }

  _flush_logs() { rm -rf "$log_dir"; }
  _flush_vendor() { rm -rf "$dir/vendor"; }

  local step=0
  step=$((step + 1)); _zion_step $step $total "Parando logger"     _flush_logger
  step=$((step + 1)); _zion_step $step $total "Parando containers" _flush_containers
  step=$((step + 1)); _zion_step $step $total "Removendo imagens"  _flush_images
  step=$((step + 1)); _zion_step $step $total "Removendo volumes"  _flush_volumes
  step=$((step + 1)); _zion_step $step $total "Limpando logs"      _flush_logs
  if [[ $has_vendor -eq 1 ]]; then
    step=$((step + 1)); _zion_step $step $total "Removendo vendor/" _flush_vendor
  fi

  _zion_done
  printf "  Rode 'zion docker %s install' para reinstalar.\n" "$service"
}
