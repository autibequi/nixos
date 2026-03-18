# Skill: Dockerizer

Analisa um projeto e gera toda a infraestrutura Docker necessaria para o workflow Zion.

## Quando usar

- User quer containerizar um novo projeto
- User quer adicionar um servico ao `zion docker`
- Precisa gerar/atualizar Dockerfile, compose, env files

## Workflow

### 1. Analise do projeto

Detectar:
- **Linguagem/framework:** Go (go.mod), Node/Nuxt (package.json), Python (requirements.txt)
- **Entrypoints:** server, worker, scheduler, migrations
- **Deps externas:** PostgreSQL, Redis, SQS/LocalStack, Elasticsearch
- **Configs existentes:** .env, Makefile, docker-compose.yaml do projeto

Comandos uteis:
```bash
# Go
cat go.mod | head -5       # module name + go version
ls apps/*/main.go          # entrypoints
grep -r "sql.Open\|gorm\|pgx" --include="*.go" -l  # DB usage

# Node
cat package.json | jq '.scripts'  # scripts
cat nuxt.config.js | head -20     # framework config
```

### 2. Gerar configs em `zion/dockerized/<service>/`

Estrutura obrigatoria:
```
zion/dockerized/<service>/
├── docker-compose.yml       # servico principal
├── docker-compose.deps.yml  # deps (postgres, redis, etc)
├── Dockerfile               # multi-stage build
├── env/
│   ├── sand.env             # sandbox (default)
│   ├── local.env            # dev local
│   ├── qa.env               # QA
│   └── prod.env             # producao (template, sem segredos)
├── init/                    # scripts de init (DB, etc)
└── README.md                # documentacao
```

### 3. Registrar no CLI

Adicionar o servico em `zion/cli/src/lib/docker_services.sh`:
- Case no `zion_docker_service_dir()` com a var de `~/.zion`
- Adicionar na lista de `zion_docker_known_services()`

### 4. Testar

```bash
zion docker run <service> --env=sand
zion docker logs <service> -f
zion docker status
zion docker stop <service>
```

### 5. Documentar

Atualizar `zion/dockerized/README.md` com o novo servico.

## Principios

- **Imagens minimas:** alpine quando possivel
- **Multi-stage builds:** builder (deps + compile) + runtime (binario + ca-certs)
- **Hot-reload em dev:** montar source como volume, usar CompileDaemon/nodemon/air
- **Producao:** imagem compilada, sem source
- **Logs em stdout/stderr:** docker logging driver captura automaticamente
- **Health checks:** em todo servico (HTTP, pg_isready, redis-cli ping)
- **Env por ambiente:** sand (default), local, qa, prod; segredos nunca commitados
- **Network:** usar `nixos_default` (external) para comunicacao entre containers Zion

## Debug remoto (Go + Docker + Cursor/VS Code)

Adicionar `Dockerfile.debug` e `docker-compose.debug.yml` ao servico.

### Dockerfile.debug
```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.24.4-alpine AS builder
RUN apk add --no-cache ca-certificates git gcc libc-dev <libs-cgo>
WORKDIR /go/app
COPY go.mod go.sum ./
COPY vendor ./vendor
COPY . .
# -gcflags desativa otimizacoes e inlining (obrigatorio para dlv)
RUN CGO_ENABLED=1 GOOS=linux go build -mod=vendor \
    -gcflags="all=-N -l" -o server ./cmd/server/main.go

# Runtime precisa ser golang:alpine (nao alpine puro) para ter go install
FROM golang:1.24.4-alpine AS runtime
RUN apk --no-cache add ca-certificates <libs-runtime>
RUN go install github.com/go-delve/delve/cmd/dlv@latest
WORKDIR /go/app
COPY --from=builder /go/app/server .
EXPOSE 4004 2345
# dlv em /go/bin/dlv (GOPATH da imagem golang:alpine, NAO /root/go/bin)
CMD ["/go/bin/dlv", "exec", "./server",
     "--headless", "--listen=:2345", "--api-version=2",
     "--accept-multiclient", "--continue"]
# ATENCAO: --continue exige --accept-multiclient obrigatoriamente
```

### docker-compose.debug.yml
```yaml
services:
  app:
    build:
      dockerfile: ${ZION_NIXOS_DIR}/zion/dockerized/<service>/Dockerfile.debug
    security_opt:
      - apparmor:unconfined   # obrigatorio para dlv
    cap_add:
      - SYS_PTRACE            # obrigatorio para dlv
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
**Notas:**
- Usar `substitutePath` (nao `remotePath`/`localRoot` — deprecated nas versoes novas)
- Nao usar `"debugAdapter": "dlv-dap"` — usa o modo legado JSON-RPC que funciona
- Debug Console mostrando "Type 'dlv help'" = conectado com sucesso (nao e erro)
- Logs do servidor vao para `zion docker logs`, nao para o Debug Console

## Templates

### Go (multi-stage)
```dockerfile
FROM golang:1.24.4-alpine AS builder
RUN apk add --no-cache git gcc libc-dev librdkafka-dev
WORKDIR /go/app
COPY go.mod go.sum ./
COPY vendor ./vendor   # vendor gerado por zion docker install
COPY . .
# CGO_ENABLED=1 + musl se usar librdkafka ou cgo
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

### Node/Nuxt
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
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]
```

### Compose patterns
```yaml
# Deps com healthcheck
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

# App com depends_on condition
services:
  app:
    depends_on:
      postgres:
        condition: service_healthy
```
