zion_load_config

cli_dir="$(dirname "$zion_compose_file")"
dockerfile="$cli_dir/Dockerfile.claude"
base_image="$(grep -m1 '^FROM' "$dockerfile" 2>/dev/null | awk '{print $2}')"

# Buildar base automaticamente se for imagem local e não existir
if [[ -n "$base_image" && "$base_image" != *"/"* ]]; then
  if ! docker image inspect "$base_image" > /dev/null 2>&1; then
    echo "Base '$base_image' não encontrada — buildando base primeiro (isso demora uma vez)..."
    DOCKER_BUILDKIT=1 docker build \
      -f "$cli_dir/Dockerfile.claude.base" \
      -t "$base_image" \
      "$cli_dir" || exit 1
  fi
fi

build_args=()
[[ -n "${args['--danger']:-}" ]] && build_args+=(--no-cache)

echo "Building claude-nix-sandbox image..."
# docker build direto — evita docker compose/Bake que tenta resolver imagens locais remotamente
DOCKER_BUILDKIT=1 docker build "${build_args[@]}" \
  -f "$dockerfile" \
  -t claude-nix-sandbox \
  "$cli_dir"
