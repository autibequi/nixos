zion_load_config

build_args=()
[[ -n "${args['--danger']:-}" ]] && build_args+=(--no-cache)

echo "Building claude-nix-sandbox image..."
zion_compose_cmd build "${build_args[@]}" leech
