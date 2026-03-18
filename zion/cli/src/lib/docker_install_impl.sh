# docker_install_impl.sh — instala dependencias de um servico usando SSH do host.
# Go:   go mod download + vendor (vendor/ fica no projeto)
# Node: npm install (node_modules/ fica no projeto)
#
# Uso: _zion_dk_install <service> <env> <worktree>

_zion_dk_install() {
  local service="$1"
  local env="${2:-sand}"
  local worktree="${3:-}"

  zion_docker_validate_service "$service" || return 1
  zion_docker_init_worktree "$service" "$worktree" || return 1

  local dir config_dir log_dir
  dir=$(zion_docker_effective_dir "$service")
  config_dir=$(zion_docker_config_dir "$service")
  log_dir=$(zion_docker_log_dir "$service")
  [[ -n "$_ZION_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_ZION_DK_WORKTREE}"

  mkdir -p "$log_dir"

  # Detectar tipo de servico
  _is_node_service() {
    [[ -f "$dir/package.json" ]]
  }

  # ── Node.js install ──────────────────────────────────────────────────────────
  if _is_node_service; then
    # Detectar versao do Node requerida (engines.node no package.json)
    local node_version
    node_version=$(node -e "const p=require('$dir/package.json'); const v=(p.engines&&p.engines.node)||'20'; console.log(v.match(/\d+/)[0])" 2>/dev/null || echo "20")
    local node_image="node:${node_version}-alpine"
    local host_uid host_gid
    host_uid="$(id -u)"
    host_gid="$(id -g)"

    echo "=== Instalando dependencias de $service (Node) [env=$env] ==="
    [[ -n "$_ZION_DK_WORKTREE" ]] && echo "  worktree: $_ZION_DK_WORKTREE"
    echo "  SSH:     ~/.ssh (montada read-only)"
    echo "  npmrc:   ~/.npmrc (montada read-only)"
    echo "  Projeto: $dir"
    echo "  Image:   $node_image"
    echo "  logs:    $log_dir/install.log"
    echo ""
    echo "Rodando: ferramentas -> npm install"
    echo "---"

    docker run \
      --rm \
      -it \
      -v "$HOME/.ssh:/ssh-host:ro" \
      -v "$HOME/.npmrc:/npmrc-host:ro" \
      -v "$dir:/app" \
      -e NPM_TOKEN="${NPM_TOKEN:-}" \
      -e TERM=xterm-256color \
      -e COLORTERM=truecolor \
      -e HOST_UID="$host_uid" \
      -e HOST_GID="$host_gid" \
      -w "/app" \
      "$node_image" \
      sh -c '
        set -e

        apk add --no-cache git openssh-client ca-certificates python3 make g++ \
          autoconf automake libtool nasm pkgconfig

        mkdir -p /root/.ssh
        cp /ssh-host/* /root/.ssh/ 2>/dev/null || true
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/* 2>/dev/null || true
        ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null

        # .npmrc: host tem prioridade; fallback para NPM_TOKEN env
        if [ -f /npmrc-host ]; then
          cp /npmrc-host /root/.npmrc
        elif [ -n "$NPM_TOKEN" ]; then
          echo "//npm.pkg.github.com/:_authToken=${NPM_TOKEN}" > /root/.npmrc
        fi
        echo "@estrategiahq:registry=https://npm.pkg.github.com/estrategiahq" >> /root/.npmrc

        echo "[1/2] Instalando dependencias (npm install)..."
        npm install
        chown -R "$HOST_UID:$HOST_GID" /app/node_modules 2>/dev/null || true

        echo "[2/2] Recompilando bindings nativos para Alpine/musl (compilando do fonte)..."
        rm -rf node_modules/node-sass/vendor/
        npm rebuild node-sass || true

        echo ""
        echo "Dependencias instaladas! node_modules/ gerado no projeto."
      ' 2>&1 | tee "$log_dir/install.log"

    if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
      echo ""
      echo "Instalacao finalizada! Rode: zion docker $service server start --env=$env"
    else
      echo ""
      echo "Instalacao falhou. Verifique: $log_dir/install.log"
      return 1
    fi

    return 0
  fi

  # ── Go install ───────────────────────────────────────────────────────────────
  local host_uid host_gid
  host_uid="$(id -u)"
  host_gid="$(id -g)"

  echo "=== Instalando dependencias de $service (Go) [env=$env] ==="
  [[ -n "$_ZION_DK_WORKTREE" ]] && echo "  worktree: $_ZION_DK_WORKTREE"
  echo "  SSH:     ~/.ssh (montada read-only)"
  echo "  Projeto: $dir"
  echo "  logs:    $log_dir/install.log"
  echo ""
  echo "Rodando: ferramentas -> go mod download -> go mod tidy -> go mod vendor"
  echo "---"

  # Roda docker run e grava em arquivo simultaneamente (preserva cores com script)
  docker run \
    --rm \
    -it \
    -v "$HOME/.ssh:/ssh-host:ro" \
    -v "$dir:/go/app" \
    -e GOPATH=/go \
    -e GOPRIVATE="github.com/estrategiahq" \
    -e TERM=xterm-256color \
    -e COLORTERM=truecolor \
    -e HOST_UID="$host_uid" \
    -e HOST_GID="$host_gid" \
    -w "/go/app" \
    "golang:1.24.4-alpine" \
    sh -c '
      set -e

      mkdir -p /root/.ssh
      cp /ssh-host/* /root/.ssh/ 2>/dev/null || true
      chmod 700 /root/.ssh
      chmod 600 /root/.ssh/* 2>/dev/null || true

      echo "[1/4] Instalando ferramentas..."
      apk add --no-cache git gcc musl-dev librdkafka-dev ca-certificates openssh-client

      git config --global url."git@github.com:estrategiahq".insteadOf "https://github.com/estrategiahq"
      ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts 2>/dev/null

      echo "[2/4] Download de modulos Go (pode demorar)..."
      go mod download

      echo "[3/4] Limpando modulos..."
      go mod tidy

      echo "[4/4] Vendoring dependencias (workspace)..."
      go work vendor
      chown -R "$HOST_UID:$HOST_GID" /go/app/vendor 2>/dev/null || true

      echo ""
      echo "Dependencias instaladas! vendor/ gerado no projeto."
    ' 2>&1 | tee "$log_dir/install.log"

  if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
    echo ""
    echo "Instalacao finalizada! Rode: zion docker $service server start --env=$env"
  else
    echo ""
    echo "Instalacao falhou. Verifique: $log_dir/install.log"
    return 1
  fi
}
