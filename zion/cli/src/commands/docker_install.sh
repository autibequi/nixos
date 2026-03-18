# Instala dependencias de um servico usando SSH do host.
# Monta ~/.ssh read-only no container e roda go mod download + build automaticamente.
# Nao expoe chaves SSH ao agente — tudo roda dentro do container isolado.

zion_load_config

service="${args[service]}"
env="${args[--env]:-sand}"

zion_docker_validate_service "$service" || exit 1

dir=$(zion_docker_service_dir "$service")
config_dir=$(zion_docker_config_dir "$service")

echo "=== Instalando dependencias de $service [env=$env] ==="
echo "  SSH:     ~/.ssh (montada read-only em /root/.ssh)"
echo "  Projeto: $dir"
echo "  Config:  $config_dir"
echo ""
echo "Rodando: ferramentas -> go mod download -> go mod tidy -> build"
echo "---"

docker run \
  --rm \
  -v "$HOME/.ssh:/ssh-host:ro" \
  -v "$dir:/go/app" \
  -e GOPATH=/go \
  -e GOPRIVATE="github.com/estrategiahq" \
  -w "/go/app" \
  "golang:1.24.4-alpine" \
  sh -c '
    set -e

    # Copiar SSH do mount read-only para diretorio com permissoes corretas
    mkdir -p /root/.ssh
    cp /ssh-host/* /root/.ssh/ 2>/dev/null || true
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/* 2>/dev/null || true

    echo "[1/4] Instalando ferramentas..."
    apk add --no-cache git gcc musl-dev librdkafka-dev ca-certificates openssh-client

    git config --global url."git@github.com:estrategiahq".insteadOf "https://github.com/estrategiahq"

    # Adiciona github.com ao known_hosts pra evitar prompt interativo
    ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts 2>/dev/null

    echo "[2/4] Download de modulos Go..."
    go mod download

    echo "[3/4] Limpando modulos..."
    go mod tidy

    echo "[4/4] Compilando server e worker..."
    CGO_ENABLED=1 GOOS=linux go build -tags musl -o server ./cmd/server/main.go
    CGO_ENABLED=1 GOOS=linux go build -tags musl -o worker ./cmd/worker/main.go

    echo ""
    echo "✅ Dependencias instaladas e binarios compilados!"
  '

if [[ $? -eq 0 ]]; then
  echo ""
  echo "✅ Instalação finalizada com sucesso!"
  echo "Agora rode: zion docker run $service --env=$env"
else
  echo ""
  echo "❌ Instalação falhou. Verifique os logs acima."
  exit 1
fi
