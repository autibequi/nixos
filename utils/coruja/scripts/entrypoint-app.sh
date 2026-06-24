#!/bin/sh
# entrypoint-app.sh — Monolito API (rede interna docker-compose)
#
# Adaptado de plug/containers/services/monolito/entrypoint-monolito-app-dev.sh.
#
# Mudanças em relação ao original:
#   1. SOCAT REMOVIDO — o original proxiava localhost:4566 → localstack:4566
#      para compatibilidade com APP_ENV=local dentro do container host-network.
#      Na rede interna, o hostname `localstack` resolve diretamente — socat
#      é desnecessário. O monolito deve usar AWS_ENDPOINT_URL=http://localstack:4566.
#
#   2. PLUG_DOTENV / PLUG_ENV_FILE não usados — env vem direto do docker-compose
#      env_file / environment. Sem source de arquivo .env no entrypoint.
#
#   3. DB_HOST, REDIS_URL já setados pelo compose como nomes de container.
#
#   4. PLUG_CONTAINER_REDIS_URL ainda respeitado (override Redis) — mantido
#      para compatibilidade com o código Go que lê essa var.

set -eu
cd /go/apps/monolito

# socat: o configuration/config_sqs.yaml usa http://localhost:4566 (hardcoded). Na rede
# de container o localstack é 'localstack:4566' — redireciona localhost:4566 → localstack.
if command -v socat >/dev/null 2>&1; then
  socat TCP-LISTEN:4566,fork,reuseaddr TCP:localstack:4566 &
fi

# Override Redis URL se PLUG_CONTAINER_REDIS_URL estiver setado.
if [ -n "${PLUG_CONTAINER_REDIS_URL:-}" ]; then
  export REDIS_URL="$PLUG_CONTAINER_REDIS_URL"
fi
if [ -n "${PLUG_CONTAINER_REDIS_STUDY_TIME_URL:-}" ]; then
  export REDIS_STUDY_TIME_URL="$PLUG_CONTAINER_REDIS_STUDY_TIME_URL"
elif [ -n "${PLUG_CONTAINER_REDIS_URL:-}" ]; then
  export REDIS_STUDY_TIME_URL="$PLUG_CONTAINER_REDIS_URL"
fi

export PATH="/go/bin:/usr/local/go/bin:${PATH:-}"
GO=/usr/local/go/bin/go

# Sem vendor no container: builda direto do mod cache (volume monolito-gomodcache) + SSH
# (GOPRIVATE). Em workspace mode (go.work) o -mod só aceita readonly|vendor; readonly usa o
# mod cache e ignora qualquer vendor/ que o editor/gopls do host crie no bind-mount — um
# vendor/ parcial fazia o Go ligar -mod=vendor sozinho e quebrar com "import lookup disabled".
export GOFLAGS=-mod=readonly

# Modo debug (Delve)
if [ "${PLUG_DEBUG_APP:-0}" = "1" ]; then
  DLV=/go/bin/dlv
  if [ ! -x "$DLV" ]; then
    echo "monolito: dlv ausente — instalando..." >&2
    "$GO" install github.com/go-delve/delve/cmd/dlv@latest
  fi
  exec "$DLV" debug ./cmd/server/main.go \
    --headless --listen=:2345 --api-version=2 --accept-multiclient --continue \
    --build-flags=-tags=musl
fi

# Modo hot reload (CompileDaemon)
CD_BIN=/go/bin/CompileDaemon
if [ ! -x "$CD_BIN" ]; then
  echo "monolito: CompileDaemon ausente — instalando..." >&2
  "$GO" install github.com/githubnemo/CompileDaemon@latest
fi
exec "$CD_BIN" \
  -build="go build -tags musl -o server ./cmd/server/main.go" \
  -command=./server \
  -directory=.
