# Build da imagem com BuildKit (habilita --mount=type=cache no Dockerfile)
cd "$zion_compose_dir" && DOCKER_BUILDKIT=1 zion_compose_cmd build
