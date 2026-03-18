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

## Templates

### Go (multi-stage)
```dockerfile
FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git gcc musl-dev
WORKDIR /go/app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /go/bin/app ./apps/server/main.go

FROM alpine:3.19 AS runtime
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=builder /go/bin/app .
EXPOSE 4004
CMD ["./app"]
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
