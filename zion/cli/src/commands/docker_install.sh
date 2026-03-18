# Instala dependencias de um servico usando SSH do host.
# Monta ~/.ssh read-only no container, roda go mod download + vendor.
# O vendor/ gerado fica no projeto — build posterior nao precisa de SSH.

zion_load_config

service="${args[service]}"
env="${args[--env]:-sand}"

zion_docker_validate_service "$service" || exit 1

dir=$(zion_docker_service_dir "$service")
config_dir=$(zion_docker_config_dir "$service")
log_dir=$(zion_docker_log_dir "$service")

mkdir -p "$log_dir"

echo "=== Instalando dependencias de $service [env=$env] ==="
echo "  SSH:     ~/.ssh (montada read-only)"
echo "  Projeto: $dir"
echo "  logs:    $log_dir/install.log"
echo ""
echo "Rodando: ferramentas -> go mod download -> go mod tidy -> go mod vendor"
echo "---"

# Roda docker run e grava em arquivo simultaneamente (preserva cores com script)
docker run \
  --rm \
  -t \
  -v "$HOME/.ssh:/ssh-host:ro" \
  -v "$dir:/go/app" \
  -e GOPATH=/go \
  -e GOPRIVATE="github.com/estrategiahq" \
  -e TERM=xterm-256color \
  -e COLORTERM=truecolor \
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

    echo ""
    echo "Dependencias instaladas! vendor/ gerado no projeto."
  ' 2>&1 | tee "$log_dir/install.log"

if [[ "${PIPESTATUS[0]}" -eq 0 ]]; then
  echo ""
  echo "Instalacao finalizada! Rode: zion docker run $service --env=$env"
else
  echo ""
  echo "Instalacao falhou. Verifique: $log_dir/install.log"
  exit 1
fi
