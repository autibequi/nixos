zion_load_config

build_args=()
[[ -n "${args['--danger']:-}" ]] && build_args+=(--no-cache)

# Auto-build zion-base:latest if not present locally (required by Dockerfile.claude)
if ! docker image inspect zion-base:latest > /dev/null 2>&1; then
  echo "zion-base:latest not found — building from Dockerfile.claude.base..."
  base_ctx="${zion_container_dir:-${HOME}/nixos/self/containers/zion}"
  docker build "${build_args[@]}" \
    -f "${base_ctx}/Dockerfile.claude.base" \
    -t zion-base:latest \
    "${base_ctx}" || { echo "Error: failed to build zion-base:latest"; exit 1; }
fi

echo "Building claude-nix-sandbox image..."
zion_compose_cmd build "${build_args[@]}" leech
