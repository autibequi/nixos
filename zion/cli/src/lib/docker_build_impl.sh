# docker_build_impl.sh — rebuilda a imagem Docker de um servico sem derrubar containers.
#
# Uso: _zion_dk_build <service> <worktree>

_zion_dk_build() {
  local service="$1"
  local worktree="${2:-}"

  zion_docker_validate_service "$service" || return 1
  zion_docker_init_worktree "$service" "$worktree" || return 1

  zion_docker_export_dirs "$service"
  _zion_dk_container_fixup
  export ZION_NIXOS_DIR="$zion_nixos_dir"

  local compose project
  compose=$(zion_docker_compose_file "$service")
  project=$(zion_docker_effective_project "$service")

  _zion_progress_init
  local label="$service"
  [[ -n "$_ZION_DK_WORKTREE" ]] && label="$service (wt: $_ZION_DK_WORKTREE)"
  _zion_header "docker build  $label"

  _build_image() {
    DOCKER_BUILDKIT=1 docker compose -f "$compose" -p "$project" build --no-cache
  }

  _zion_step 1 1 "Building image" _build_image || return 1
  _zion_done
  printf "  Rode 'zion docker %s server start' para subir.\n" "$service"
}
