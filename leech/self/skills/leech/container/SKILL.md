---
name: leech/container
description: Dockerizar um novo servico no ecossistema Leech — gerar Dockerfile/compose/envs e integrar com leech docker (logs em /workspace/logs, aparece no leech status, registrado no CLI). Tambem cobre operar servicos existentes (monolito, bo-container, front-student).
---

# Skill: leech/container

Criar e operar containers integrados ao ecossistema Leech: logs persistentes, visibilidade no `leech docker status`, registro no CLI, rede compartilhada.

## Quando usar

- Dockerizar um projeto novo (gerar Dockerfile, compose, envs, registrar no CLI)
- Levantar / parar / debugar servicos existentes (`leech docker run/stop/logs/...`)
- Investigar problemas de container (logs, shell, status)
- Configurar debug remoto Go + dlv + Cursor

---

## Modo 1 — Novo servico (gerar infra)

### 1. Analisar o projeto

Detectar linguagem, entrypoints e dependencias:

```bash
# Go
cat go.mod | head -5              # module + go version
ls apps/*/main.go                 # entrypoints
grep -r "sql.Open\|gorm\|pgx" --include="*.go" -l  # DB

# Node
cat package.json | jq '.scripts'
cat nuxt.config.js | head -20
```

Dependencias externas a detectar: PostgreSQL, Redis, SQS/LocalStack, Elasticsearch.

### 2. Gerar `leech/containers/<service>/`

```
leech/containers/<service>/
├── Dockerfile               # multi-stage
├── Dockerfile.debug         # com dlv (Go)
├── docker-compose.yml       # servico principal
├── docker-compose.deps.yml  # postgres, redis, etc
├── docker-compose.debug.yml # override dlv
├── env/
│   ├── sand.env             # sandbox (default)
│   ├── local.env
│   ├── qa.env
│   └── prod.env             # template, sem segredos
├── init/                    # scripts DB (ex: 01_init_db.sql)
└── README.md
```

### 3. Registrar no CLI

Editar `leech/cli/src/lib/docker_services.sh`:
- `leech_docker_service_dir()` — case com var de `~/.leech`
- `leech_docker_known_services()` — adicionar na lista

### 4. Templates

#### Go (multi-stage)
```dockerfile
FROM golang:1.24.4-alpine AS builder
RUN apk add --no-cache git gcc libc-dev librdkafka-dev
WORKDIR /go/app
COPY go.mod go.sum ./
COPY vendor ./vendor
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl -o server ./cmd/server/main.go

FROM alpine:latest AS runtime
RUN apk --no-cache add ca-certificates librdkafka tzdata
WORKDIR /go/app
COPY --from=builder /go/app/server .
EXPOSE 4004
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4004/health || exit 1
CMD ["./server"]
```

#### Node/Nuxt
```dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN yarn build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/.output ./.output
EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
```

#### Compose — deps com healthcheck
```yaml
services:
  postgres:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  app:
    depends_on:
      postgres:
        condition: service_healthy
```

---

## Modo 2 — Operar servicos existentes

### CLI `leech docker`

```bash
leech docker run <service> [--env=sand] [--detach] [--debug]
leech docker stop <service>
leech docker logs <service> [-f] [--tail=100]
leech docker status [service]
leech docker shell <service> [container]
leech docker restart <service>
leech docker flush <service>      # remove volumes anonimos
leech docker install <service>    # go work vendor / npm install
```

### Logs no container

| Arquivo | Conteudo |
|---|---|
| `/workspace/logs/docker/<service>/service.log` | runtime (docker compose logs) |
| `/workspace/logs/docker/<service>/startup.log` | build/startup |
| `/workspace/logs/docker/<service>/deps.log` | dependencias |
| `/workspace/logs/docker/<service>/install.log` | go mod download |

Host: `~/.local/share/leech/logs/<service>/`

### Servicos conhecidos

#### monolito
- Go 1.24.4, CGO_ENABLED=1, -tags musl (librdkafka)
- Entrypoints: `./cmd/server/main.go` (porta 4004), `./cmd/worker/main.go`
- `go.work` workspace com modulos filhos; vendor via `go work vendor`
- Health: `GET /health`
- 6 verticais: concursos, medicina, oab, vestibulares, militares, carreiras-juridicas
- Erros nao-criticos locais:
  - `ERRO no Client Coruja-AI nenhum endpoint configurado` — env faltando, sobe normal
  - `Falha ao realizar parse da chave privada para assinar cloudfront` — env faltando
  - `Toggler: unexpected end of JSON input` — bate ~1min, usa cache, ok

#### bo-container
- Node 14 Alpine, Quasar 1.x + Vue 2
- npm install durante `docker compose build` (sem `leech docker install`)
- SSH agent via `--mount=type=ssh` (para `frontend-libs` git+ssh)
- `NPM_TOKEN` como build arg (GitHub Package Registry)
- Dev server HTTPS em `:9090` (hardcoded no quasar.conf.js)
- `LOCAL_BO_CONTAINER_HOST=0.0.0.0`
- Hot-reload: bind mount source + volume anonimo em `/app/node_modules`
- Sem deps compose
- Para atualizar node_modules: `leech docker flush bo-container && leech docker run bo-container`

---

## Debug remoto (Go + dlv + Cursor)

### Dockerfile.debug
```dockerfile
FROM golang:1.24.4-alpine AS builder
RUN apk add --no-cache ca-certificates git gcc libc-dev
WORKDIR /go/app
COPY go.mod go.sum ./
COPY vendor ./vendor
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -mod=vendor \
    -gcflags="all=-N -l" -o server ./cmd/server/main.go

FROM golang:1.24.4-alpine AS runtime
RUN apk --no-cache add ca-certificates
RUN go install github.com/go-delve/delve/cmd/dlv@latest
WORKDIR /go/app
COPY --from=builder /go/app/server .
EXPOSE 4004 2345
# dlv fica em /go/bin/dlv (GOPATH da imagem golang:alpine)
CMD ["/go/bin/dlv", "exec", "./server",
     "--headless", "--listen=:2345", "--api-version=2",
     "--accept-multiclient", "--continue"]
# ATENCAO: --continue exige --accept-multiclient
```

### docker-compose.debug.yml
```yaml
services:
  app:
    build:
      dockerfile: ${LEECH_NIXOS_DIR}/leech/containers/<service>/Dockerfile.debug
    security_opt:
      - apparmor:unconfined
    cap_add:
      - SYS_PTRACE
```

### launch.json (Cursor/VS Code)
```json
{
  "name": "[DOCKER] Attach to <service>",
  "type": "go",
  "request": "attach",
  "mode": "remote",
  "port": 2345,
  "host": "127.0.0.1",
  "showLog": true,
  "substitutePath": [
    { "from": "${workspaceFolder}", "to": "/go/app" }
  ]
}
```

**Regras dlv:**
- Usar `substitutePath` (nao `remotePath`/`localRoot` — deprecated)
- Nao usar `"debugAdapter": "dlv-dap"` — usar modo JSON-RPC legado
- "Type 'dlv help'" no Debug Console = conectado com sucesso (nao e erro)
- Logs do servidor → `leech docker logs`, nao no Debug Console

---

## Principios

- Imagens minimas: alpine sempre que possivel
- Multi-stage: builder (deps + compile) + runtime (binario + ca-certs)
- Hot-reload em dev: montar source como volume
- Logs em stdout/stderr (docker logging driver captura)
- Health checks em todo servico
- Envs por ambiente: sand (default), local, qa, prod — segredos nunca commitados
- Network: `nixos_default` (external) para comunicacao entre containers Leech
