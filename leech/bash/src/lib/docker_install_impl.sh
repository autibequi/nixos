# docker_install_impl.sh — instala dependencias de um servico usando SSH do host.
# Go:   go mod download + vendor (vendor/ fica no projeto)
# Node: npm/pnpm/bun install (node_modules/ fica no projeto via bind mount)
#
# Uso: _leech_dk_install <service> <env> <worktree>
#
# Package manager (Node): auto-detectado pelo lockfile presente no projeto.
#   bun.lockb       → bun  (imagem oven/bun:alpine)
#   pnpm-lock.yaml  → pnpm (node image + pnpm + volume leech-pnpm-store)
#   package-lock.json (default) → npm  (node image + volume leech-npm-cache-nodeN)
# Override: LEECH_PKG_MANAGER=npm|pnpm|bun
# Node 14: forca npm (bun/pnpm incompativeis com node-sass em musl)
#
# Smart skip: se node_modules/.leech-install-hash == sha256(lockfile), pula install.

_leech_dk_install() {
  local service="$1"
  local env="${2:-sand}"
  local worktree="${3:-}"

  leech_docker_validate_service "$service" || return 1
  leech_docker_init_worktree "$service" "$worktree" || return 1

  # Exportar e fixar paths para container→host translation
  leech_docker_export_dirs "$service"
  _leech_dk_container_fixup

  local dir config_dir log_dir
  dir=$(leech_docker_effective_dir "$service")
  config_dir=$(leech_docker_config_dir "$service")
  log_dir=$(leech_docker_log_dir "$service")
  [[ -n "$_LEECH_DK_WORKTREE" ]] && log_dir="${log_dir}/wt-${_LEECH_DK_WORKTREE}"

  leech_ensure_log_dir "$log_dir"

  # Detectar tipo de servico
  _is_node_service() {
    [[ -f "$dir/package.json" ]]
  }

  # ── Node.js install ──────────────────────────────────────────────────────────
  if _is_node_service; then
    # Detectar versao do Node requerida (engines.node no package.json)
    local node_version
    node_version=$(node -e "const p=require('$dir/package.json'); const v=(p.engines&&p.engines.node)||'20'; console.log(v.match(/\d+/)[0])" 2>/dev/null || echo "20")

    # Detectar package manager: override > lockfile existente > npm
    local pkg_manager="${LEECH_PKG_MANAGER:-}"
    if [[ -z "$pkg_manager" ]]; then
      if [[ -f "$dir/bun.lockb" ]];        then pkg_manager="bun"
      elif [[ -f "$dir/pnpm-lock.yaml" ]]; then pkg_manager="pnpm"
      else                                      pkg_manager="npm"
      fi
    fi

    # Node 14: forcado npm — bun/pnpm incompativeis com node-sass em musl/Alpine
    if [[ "$node_version" == "14" && "$pkg_manager" != "npm" ]]; then
      printf "  \033[33mNode 14 detectado: forcando npm (compatibilidade node-sass/musl)\033[0m\n"
      pkg_manager="npm"
    fi

    # Lockfile de referencia para hash
    local lockfile="$dir/package-lock.json"
    [[ "$pkg_manager" == "pnpm" ]] && lockfile="$dir/pnpm-lock.yaml"
    [[ "$pkg_manager" == "bun"  ]] && lockfile="$dir/bun.lockb"

    # Smart skip: se node_modules/.leech-install-hash == sha256(lockfile), pula
    local sentinel="$dir/node_modules/.leech-install-hash"
    if [[ -d "$dir/node_modules" && -f "$sentinel" && -f "$lockfile" ]]; then
      local current_hash stored_hash
      current_hash=$(sha256sum "$lockfile" 2>/dev/null | cut -d' ' -f1)
      stored_hash=$(cat "$sentinel" 2>/dev/null)
      if [[ -n "$current_hash" && "$current_hash" == "$stored_hash" ]]; then
        _leech_header "docker install  $service (Node ${node_version} / ${pkg_manager})  [env=$env]"
        printf "  \033[32mnode_modules ja esta atualizado\033[0m (hash identico, pulando install)\n"
        printf "  Rode: leech docker %s server start --env=%s\n\n" "$service" "$env"
        return 0
      fi
    fi

    # Imagem e volumes de cache por package manager
    local node_image cache_vol cache_mount
    case "$pkg_manager" in
      bun)
        node_image="oven/bun:alpine"
        cache_vol="leech-bun-cache"
        cache_mount="/root/.bun/install/cache"
        ;;
      pnpm)
        node_image="node:${node_version}-alpine"
        cache_vol="leech-pnpm-store"
        cache_mount="/pnpm-store"
        ;;
      npm)
        node_image="node:${node_version}-alpine"
        cache_vol="leech-npm-cache-node${node_version}"
        cache_mount="/root/.npm"
        ;;
    esac

    local host_uid host_gid
    host_uid="$(id -u)"
    host_gid="$(id -g)"

    _leech_header "docker install  $service (Node ${node_version} / ${pkg_manager})  [env=$env]"
    printf "  \033[2mimage: %s  cache: %s  •  logs: %s/install.log\033[0m\n\n" \
      "$node_image" "$cache_vol" "$log_dir"

    local ssh_dir="${HOST_SSH_DIR:-$HOME/.ssh}"
    local npmrc="${HOST_NPMRC:-$HOME/.npmrc}"
    docker run \
      --rm \
      -it \
      -v "$ssh_dir:/ssh-host:ro" \
      -v "$npmrc:/npmrc-host:ro" \
      -v "$dir:/app" \
      -v "${cache_vol}:${cache_mount}" \
      -e NPM_TOKEN="${NPM_TOKEN:-}" \
      -e TERM=xterm-256color \
      -e COLORTERM=truecolor \
      -e HOST_UID="$host_uid" \
      -e HOST_GID="$host_gid" \
      -e PKG_MANAGER="$pkg_manager" \
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

        # Autenticacao npm/github packages
        if [ -f /npmrc-host ]; then
          cp /npmrc-host /root/.npmrc
        elif [ -n "$NPM_TOKEN" ]; then
          echo "//npm.pkg.github.com/:_authToken=${NPM_TOKEN}" > /root/.npmrc
        fi
        echo "@estrategiahq:registry=https://npm.pkg.github.com/estrategiahq" >> /root/.npmrc

        case "$PKG_MANAGER" in
          bun)
            echo "[1/2] Instalando dependencias (bun install)..."
            bun install
            ;;
          pnpm)
            echo "[1/2] Instalando pnpm + dependencias..."
            npm install -g pnpm --prefer-offline --quiet
            pnpm install --store-dir /pnpm-store --no-frozen-lockfile
            ;;
          npm)
            echo "[1/2] Instalando dependencias (npm install)..."
            npm install

            echo "[2/2] Recompilando bindings nativos para Alpine/musl..."
            rm -rf node_modules/node-sass/vendor/ 2>/dev/null || true
            npm rebuild node-sass 2>/dev/null || true
            ;;
        esac

        # Sentinel hash para smart skip na proxima chamada
        LOCKFILE="package-lock.json"
        [ "$PKG_MANAGER" = "pnpm" ] && LOCKFILE="pnpm-lock.yaml"
        [ "$PKG_MANAGER" = "bun"  ] && LOCKFILE="bun.lockb"
        if [ -f "$LOCKFILE" ]; then
          sha256sum "$LOCKFILE" | cut -d" " -f1 > node_modules/.leech-install-hash
        fi

        chown -R "$HOST_UID:$HOST_GID" /app/node_modules 2>/dev/null || true

        echo ""
        echo "Dependencias instaladas! node_modules/ gerado no projeto."
      ' 2>&1 | tee "$log_dir/install.log"

    if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
      # Adicionar artefatos ao .git/info/exclude local
      local exclude_file="$dir/.git/info/exclude"
      if [[ -f "$dir/.git/info/exclude" ]] || [[ -d "$dir/.git" ]]; then
        mkdir -p "$dir/.git/info"
        for entry in 'node_modules/' 'pnpm-lock.yaml' 'bun.lockb'; do
          if ! grep -qxF "$entry" "$exclude_file" 2>/dev/null; then
            echo "$entry" >> "$exclude_file"
          fi
        done
      fi
      printf "\n  \033[32m\033[1mFeito!\033[0m  Rode: leech docker %s server start --env=%s\n\n" "$service" "$env"
    else
      printf "\n  \033[31mInstalacao falhou.\033[0m  Verifique: %s/install.log\n\n" "$log_dir"
      return 1
    fi

    return 0
  fi

  # ── Go install ───────────────────────────────────────────────────────────────
  local host_uid host_gid
  host_uid="$(id -u)"
  host_gid="$(id -g)"

  _leech_header "docker install  $service (Go)  [env=$env]"
  printf "  \033[2mlogs: %s/install.log\033[0m\n\n" "$log_dir"

  # Roda docker run e grava em arquivo simultaneamente (preserva cores com script)
  docker run \
    --rm \
    -it \
    -v "${HOST_SSH_DIR:-$HOME/.ssh}:/ssh-host:ro" \
    -v "$dir:/go/app" \
    -v "leech-go-mod-cache:/go/pkg/mod" \
    -v "leech-go-build-cache:/root/.cache/go-build" \
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
    # Adicionar vendor/ ao .git/info/exclude local para nao sujar o git do projeto
    local exclude_file="$dir/.git/info/exclude"
    if [[ -f "$dir/.git/info/exclude" ]] || [[ -d "$dir/.git" ]]; then
      mkdir -p "$dir/.git/info"
      if ! grep -qxF 'vendor/' "$exclude_file" 2>/dev/null; then
        echo 'vendor/' >> "$exclude_file"
      fi
    fi
    printf "\n  \033[32m\033[1mFeito!\033[0m  Rode: leech docker %s server start --env=%s\n\n" "$service" "$env"
  else
    printf "\n  \033[31mInstalacao falhou.\033[0m  Verifique: %s/install.log\n\n" "$log_dir"
    return 1
  fi
}
