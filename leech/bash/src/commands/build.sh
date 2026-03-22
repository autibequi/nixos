zion_load_config

build_args=()
[[ -n "${args['--danger']:-}" ]] && build_args+=(--no-cache)

# Auto-build leech-base:latest if not present locally (required by Dockerfile.claude)
if ! docker image inspect leech-base:latest > /dev/null 2>&1; then
  echo "leech-base:latest not found — building from Dockerfile.claude.base..."
  base_ctx="${zion_container_dir:-${HOME}/nixos/self/containers/zion}"
  docker build "${build_args[@]}" \
    -f "${base_ctx}/Dockerfile.claude.base" \
    -t leech-base:latest \
    "${base_ctx}" || { echo "Error: failed to build leech-base:latest"; exit 1; }
fi

echo "Building leech image..."
zion_compose_cmd build "${build_args[@]}" leech
