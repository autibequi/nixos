# docker_install_impl.sh — instala dependencias de um servico usando SSH do host.
# Go:   go mod download + vendor (vendor/ fica no projeto)
# Node: npm install (node_modules/ fica no projeto)
#
# Uso: _leech_dk_install <service> <env> <worktree>
#
# SSH: prefere SSH agent socket (SSH_AUTH_SOCK) — chave privada nunca entra no container.
# Fallback: monta ~/.ssh como volume read-only (comportamento legado).

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

  # ── SSH: agent socket (prefere) vs chave raw (fallback) ──────────────────────
  # Com agent socket: chave privada NUNCA entra no container — mais seguro.
  # Fallback para chave raw quando SSH_AUTH_SOCK nao disponivel.
  local ssh_vol_args=()
  local ssh_setup_script
  if [[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]]; then
    ssh_vol_args=(
      -v "$SSH_AUTH_SOCK:/ssh-agent.sock"
      -e SSH_AUTH_SOCK=/ssh-agent.sock
    )
    ssh_setup_script='mkdir -p /root/.ssh && ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null'
  else
    local ssh_dir="${HOST_SSH_DIR:-$HOME/.ssh}"
    ssh_vol_args=(-v "$ssh_dir:/ssh-host:ro")
    ssh_setup_script='mkdir -p /root/.ssh && cp /ssh-host/* /root/.ssh/ 2>/dev/null || true && chmod 700 /root/.ssh && chmod 600 /root/.ssh/* 2>/dev/null || true && ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null'
  fi

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

    _leech_header "docker install  $service (Node)  [env=$env]"
    printf "  \033[2mimage: %s  •  logs: %s/install.log\033[0m\n\n" "$node_image" "$log_dir"

    local npmrc="${HOST_NPMRC:-$HOME/.npmrc}"
    docker run \
      --rm \
      -it \
      "${ssh_vol_args[@]}" \
      -v "$npmrc:/npmrc-host:ro" \
      -v "$dir:/app" \
      -e NPM_TOKEN="${NPM_TOKEN:-}" \
      -e TERM=xterm-256color \
      -e COLORTERM=truecolor \
      -e HOST_UID="$host_uid" \
      -e HOST_GID="$host_gid" \
      -w "/app" \
      "$node_image" \
      sh -c "
        set -e

        apk add --no-cache git openssh-client ca-certificates python3 make g++ \
          autoconf automake libtool nasm pkgconfig

        ${ssh_setup_script}

        # .npmrc: host tem prioridade; fallback para NPM_TOKEN env
        if [ -f /npmrc-host ]; then
          cp /npmrc-host /root/.npmrc
        elif [ -n \"\$NPM_TOKEN\" ]; then
          echo \"//npm.pkg.github.com/:_authToken=\${NPM_TOKEN}\" > /root/.npmrc
        fi
        echo \"@estrategiahq:registry=https://npm.pkg.github.com/estrategiahq\" >> /root/.npmrc

        echo \"[1/2] Instalando dependencias (npm install)...\"
        npm install
        chown -R \"\$HOST_UID:\$HOST_GID\" /app/node_modules 2>/dev/null || true

        echo \"[2/2] Recompilando bindings nativos para Alpine/musl (compilando do fonte)...\"
        rm -rf node_modules/node-sass/vendor/
        npm rebuild node-sass || true

        echo \"\"
        echo \"Dependencias instaladas! node_modules/ gerado no projeto.\"
      " 2>&1 | tee "$log_dir/install.log"

    if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
      # Adicionar node_modules/ ao .git/info/exclude local para nao sujar o git do projeto
      local exclude_file="$dir/.git/info/exclude"
      if [[ -f "$dir/.git/info/exclude" ]] || [[ -d "$dir/.git" ]]; then
        mkdir -p "$dir/.git/info"
        if ! grep -qxF 'node_modules/' "$exclude_file" 2>/dev/null; then
          echo 'node_modules/' >> "$exclude_file"
        fi
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
    "${ssh_vol_args[@]}" \
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
    sh -c "
      set -e

      ${ssh_setup_script}

      echo \"[1/4] Instalando ferramentas...\"
      apk add --no-cache git gcc musl-dev librdkafka-dev ca-certificates openssh-client

      git config --global url.\"git@github.com:estrategiahq\".insteadOf \"https://github.com/estrategiahq\"

      echo \"[2/4] Download de modulos Go (pode demorar)...\"
      go mod download

      echo \"[3/4] Limpando modulos...\"
      go mod tidy

      echo \"[4/4] Vendoring dependencias (workspace)...\"
      go work vendor
      chown -R \"\$HOST_UID:\$HOST_GID\" /go/app/vendor 2>/dev/null || true

      echo \"\"
      echo \"Dependencias instaladas! vendor/ gerado no projeto.\"
    " 2>&1 | tee "$log_dir/install.log"

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
