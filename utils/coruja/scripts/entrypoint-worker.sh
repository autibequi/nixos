#!/bin/sh
# entrypoint-worker.sh — Monolito Worker (rede interna docker-compose)
#
# Adaptado de plug/containers/services/monolito/entrypoint-monolito-worker-dev.sh.
#
# Mudanças em relação ao original:
#   1. PLUG_DOTENV / PLUG_ENV_FILE não usados — env vem do compose diretamente.
#   2. DB_HOST e REDIS_URL já chegam corretos via environment do compose.
#   3. Mantido PLUG_CONTAINER_REDIS_URL override para compat com código Go.

set -eu
cd /go/apps/monolito

# socat: o configuration/config_sqs.yaml usa http://localhost:4566 (hardcoded). Na rede
# de container o localstack é 'localstack:4566' — redireciona localhost:4566 → localstack.
if command -v socat >/dev/null 2>&1; then
  socat TCP-LISTEN:4566,fork,reuseaddr TCP:localstack:4566 &
fi

# Override Redis URL
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

# Garante que todos os módulos do go.mod estão no cache antes de ligar -mod=readonly.
"$GO" mod download

# Sem vendor no container: builda direto do mod cache (volume monolito-gomodcache) + SSH
# (GOPRIVATE). Em workspace mode (go.work) o -mod só aceita readonly|vendor; readonly usa o
# mod cache e ignora qualquer vendor/ que o editor/gopls do host crie no bind-mount.
export GOFLAGS=-mod=readonly

# Modo debug (Delve)
if [ "${PLUG_DEBUG_WORKER:-0}" = "1" ]; then
  DLV=/go/bin/dlv
  if [ ! -x "$DLV" ]; then
    echo "monolito-worker: dlv ausente — instalando..." >&2
    "$GO" install github.com/go-delve/delve/cmd/dlv@latest
  fi
  exec "$DLV" debug ./cmd/worker/main.go \
    --headless --listen=:2346 --api-version=2 --accept-multiclient --continue \
    --build-flags="-tags musl"
fi

# Modo hot reload (CompileDaemon)
CD_BIN=/go/bin/CompileDaemon
if [ ! -x "$CD_BIN" ]; then
  echo "monolito-worker: CompileDaemon ausente — instalando..." >&2
  "$GO" install github.com/githubnemo/CompileDaemon@latest
fi
exec "$CD_BIN" \
  -build="go build -tags musl -o worker ./cmd/worker/main.go" \
  -command=./worker \
  -directory=.
