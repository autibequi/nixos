leech_load_config

build_args=()
[[ -n "${args['--danger']:-}" ]] && build_args+=(--no-cache)

base_ctx="${leech_container_dir:-${HOME}/nixos/leech/docker/leech}"

# --danger força rebuild da base (cursor-agent expira — use quando agent sair silenciosamente)
if [[ -n "${args['--danger']:-}" ]]; then
  echo "leech-base:latest — rebuild forçado (--danger)..."
  docker build "${build_args[@]}" \
    -f "${base_ctx}/Dockerfile.claude.base" \
    -t leech-base:latest \
    "${base_ctx}" || { echo "Error: failed to build leech-base:latest"; exit 1; }
elif ! docker image inspect leech-base:latest > /dev/null 2>&1; then
  echo "leech-base:latest not found — building from Dockerfile.claude.base..."
  docker build \
    -f "${base_ctx}/Dockerfile.claude.base" \
    -t leech-base:latest \
    "${base_ctx}" || { echo "Error: failed to build leech-base:latest"; exit 1; }
fi

echo "Building leech image..."
leech_compose_cmd build "${build_args[@]}" leech
