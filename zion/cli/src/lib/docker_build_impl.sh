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

  echo "=== [docker build] $service ==="
  docker compose -f "$compose" -p "$project" build --no-cache
  echo ""
  echo "Imagem rebuilt. Rode 'zion docker $service server start' para subir."
}
