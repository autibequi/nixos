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
    local cli_dir
    cli_dir="$(dirname "$compose")"
    local dockerfile="$cli_dir/Dockerfile.claude"
    local base_image
    base_image=$(grep -m1 "^FROM" "$dockerfile" 2>/dev/null | awk '{print $2}')

    # Se a imagem base é local (sem registry), buildar base primeiro se não existir
    if [[ -n "$base_image" && "$base_image" != *"/"* && "$base_image" != *":"*"."* ]]; then
      if ! docker image inspect "$base_image" > /dev/null 2>&1; then
        echo "  Base '$base_image' não encontrada — buildando base primeiro..."
        DOCKER_BUILDKIT=1 docker build \
          -f "$cli_dir/Dockerfile.claude.base" \
          -t "$base_image" \
          "$cli_dir" || return 1
      fi
    fi

    # docker build direto — evita Bake que tenta resolver imagens locais remotamente
    local image_name
    image_name=$(docker compose -f "$compose" config --format json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); svc=list(d['services'].values())[0]; print(svc.get('image','claude-nix-sandbox'))" 2>/dev/null || echo "claude-nix-sandbox")
    DOCKER_BUILDKIT=1 docker build \
      -f "$dockerfile" \
      -t "$image_name" \
      "$cli_dir"
  }

  _zion_step 1 1 "Building image" _build_image || return 1
  _zion_done
  printf "  Rode 'zion docker %s server start' para subir.\n" "$service"
}
