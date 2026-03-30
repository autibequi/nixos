---
name: vennon
description: "Auto-ativar quando: usuario menciona vennon, deck, yaa, vennon CLI, containers Docker, upgrade do vennon, build Rust, servicos (monolito, bo-container, front-student), docker-compose, debug remoto dlv."
---

# vennon — CLI e Containers

Skill unificada para o ecossistema de ferramentas do vennon: CLI Rust (yaa/deck/vennon), containers Docker, e upgrade do proprio vennon.

---

## Mapa do vennon

```
/workspace/host/vennon/
├── rust/                       CLI Rust (fonte da verdade)
│   ├── Cargo.toml              workspace
│   ├── justfile                build targets (just build, just install)
│   └── crates/vennon-cli/
│       └── src/
│           ├── main.rs         Clap enum + dispatch (4 dominios: Session/Agents/Services/System)
│           ├── help.rs         Banner, man page, before_help blocks
│           ├── config.rs       Figment config (defaults -> YAML -> env -> CLI)
│           ├── commands/       handlers (session, agents, runner, docker, host, tools, config_cmd, ...)
│           ├── tui/            TUI dashboard (ratatui)
│           └── *.rs            core logic (paths, session, model, agents, compose, executor, ...)
├── bash/                       legado (mantido para referencia, NAO e o ativo)
├── docker/                     docker-compose por servico
└── self/                       self-knowledge do sistema

/workspace/self/                runtime engine (sempre rw, editar diretamente)
├── skills/                     namespace de skills
├── agents/                     cards de agentes (frontmatter + instrucoes)
├── hooks/                      hooks (Claude + Cursor + ENGINE)
└── scripts/                    scripts utilitarios bash/python

~/.config/vennon/config.yaml     config estruturado (Figment YAML provider)
~/.vennon                        tokens + env vars (bash-sourceable, legado)
```

### Arquitetura de config — Figment layered

```
Built-in defaults -> config.yaml -> vennon_* env vars -> CLI flags
        ^                ^              ^                ^
   config.rs         ~/.config/    Env::prefixed     Clap args
   Default impl      vennon/        ("VENNON_")        (Option<T>)
```

Struct unificada: `vennonConfig` com sub-structs `session`, `runner`, `agents`, `paths`, `system`, `secrets`.

---

## Containers — Criar e Operar

### Quando usar

- Dockerizar um projeto novo (gerar Dockerfile, compose, envs, registrar no CLI)
- Levantar / parar / debugar servicos existentes (`vennon run/stop/logs/...`)
- Investigar problemas de container (logs, shell, status)
- Configurar debug remoto Go + dlv + Cursor

### CLI `vennon` — Comandos de servico

```bash
vennon run <service> [--env=sand] [--detach] [--debug]
vennon stop <service>
vennon logs <service> [-f] [--tail=100]
vennon status [service]
vennon shell <service> [container]
vennon restart <service>
vennon flush <service>      # remove volumes anonimos
vennon install <service>    # go work vendor / npm install
```

### Novo servico — gerar infra

#### 1. Analisar o projeto

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

#### 2. Gerar `vennon/containers/<service>/`

```
vennon/containers/<service>/
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

#### 3. Registrar no CLI

Editar `vennon/cli/src/lib/docker_services.sh`:
- `vennon_docker_service_dir()` — case com var de `~/.vennon`
- `vennon_docker_known_services()` — adicionar na lista

### Templates

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

### Logs no container

| Arquivo | Conteudo |
|---|---|
| `/workspace/logs/docker/<service>/service.log` | runtime (docker compose logs) |
| `/workspace/logs/docker/<service>/startup.log` | build/startup |
| `/workspace/logs/docker/<service>/deps.log` | dependencias |
| `/workspace/logs/docker/<service>/install.log` | go mod download |

Host: `~/.local/share/vennon/logs/<service>/`

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
- npm install durante `docker compose build` (sem `vennon install`)
- SSH agent via `--mount=type=ssh` (para `frontend-libs` git+ssh)
- `NPM_TOKEN` como build arg (GitHub Package Registry)
- Dev server HTTPS em `:9090` (hardcoded no quasar.conf.js)
- `LOCAL_BO_CONTAINER_HOST=0.0.0.0`
- Hot-reload: bind mount source + volume anonimo em `/app/node_modules`
- Sem deps compose
- Para atualizar node_modules: `vennon flush bo-container && vennon run bo-container`

### Debug remoto (Go + dlv + Cursor)

#### Dockerfile.debug
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
CMD ["/go/bin/dlv", "exec", "./server",
     "--headless", "--listen=:2345", "--api-version=2",
     "--accept-multiclient", "--continue"]
```

#### docker-compose.debug.yml
```yaml
services:
  app:
    build:
      dockerfile: ${vennon_NIXOS_DIR}/vennon/containers/<service>/Dockerfile.debug
    security_opt:
      - apparmor:unconfined
    cap_add:
      - SYS_PTRACE
```

#### launch.json (Cursor/VS Code)
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
- Logs do servidor -> `vennon logs`, nao no Debug Console

### Principios de containers

- Imagens minimas: alpine sempre que possivel
- Multi-stage: builder (deps + compile) + runtime (binario + ca-certs)
- Hot-reload em dev: montar source como volume
- Logs em stdout/stderr (docker logging driver captura)
- Health checks em todo servico
- Envs por ambiente: sand (default), local, qa, prod — segredos nunca commitados
- Network: `nixos_default` (external) para comunicacao entre containers vennon

---

## Upgrade do vennon — Workflow de Desenvolvimento

### Tipo de mudanca — onde trabalhar

| Tipo | Onde editar |
|------|-------------|
| CLI — novo comando ou flag | `/workspace/host/vennon/rust/crates/vennon-cli/src/` |
| CLI — logica de comando existente | `/workspace/host/vennon/rust/crates/vennon-cli/src/commands/` |
| Docker — compose, Dockerfile | `/workspace/host/vennon/docker/` |
| Agente — comportamento, schedule, model | `/workspace/self/ego/<nome>/agent.md` |
| Skill — criar ou atualizar | `/workspace/self/skills/` |
| Hook — pre/post-tool, session-start | `/workspace/self/hooks/` |
| Script utilitario | `/workspace/self/scripts/` |

### Workflow A — CLI / Docker / Rust

#### 1. Mapear o que precisa mudar

Para CLI Rust, identificar:
- Novo comando? Adicionar variante em `enum Commands` em `main.rs` + dispatch + funcao em `commands/`
- Nova flag global? Adicionar em `Cli` struct
- Logica de comando existente? Editar o `.rs` correspondente em `commands/`
- Atualizar exemplos em `help.rs` (DIRECTIVE: obrigatorio a cada mudanca)

#### 3. Implementar e testar

```bash
# Compilar
nix-shell -p rustc cargo --run \
  "cd /workspace/host/vennon/rust && cargo build --release -p vennon-cli 2>&1 | tail -5"

# Executar o binario diretamente
/workspace/host/vennon/rust/target/release/vennon <comando> --help
/workspace/host/vennon/rust/target/release/vennon <comando> <args>
```

#### 4. Commitar

```bash
git -C /workspace/host add -p
git -C /workspace/host commit -m "feat(vennon): <descricao concisa>"
```

### Workflow B — Self (agents, skills, hooks, scripts)

Editar diretamente em `/workspace/self/`. E o runtime vivo da sessao.

### Casos comuns

#### Adicionar novo comando ao CLI

1. Adicionar funcao em `commands/<modulo>.rs` (ou criar novo modulo + registrar em `commands/mod.rs`)
2. Adicionar variante em `enum Commands` em `main.rs`
3. Se o comando precisa de defaults configuraveis: usar `Option<T>` nos args + fallback `cfg.runner.*` / `cfg.agents.*`
4. Adicionar dispatch no `match` de `main.rs`
5. Adicionar exemplos em `help.rs` (DIRECTIVE obrigatorio)
6. Compilar e testar: `vennon <nome> --help` e `vennon <nome> <args>`

#### Modificar comando existente

1. Editar `commands/<modulo>.rs`
2. Se mudou assinatura: atualizar `main.rs` + `help.rs`
3. Se adicionou flag com default configuravel: trocar `default_value` por `Option` + fallback `vennonConfig`
4. Compilar e testar comportamento antigo + novo

#### Adicionar campo ao config

1. Adicionar campo na sub-struct relevante em `config.rs` (SessionConfig, RunnerConfig, etc.)
2. Adicionar `#[serde(default = "...")]` com valor built-in
3. Atualizar `Default impl` e `display()` em `config.rs`
4. Atualizar `DEFAULT_TEMPLATE` em `config.rs`
5. Env var automatica: `vennon_<SECTION>_<FIELD>` (ex: `vennon_RUNNER_ENV=sand`)

### Regras de ouro

- **Sempre testar antes de declarar pronto** — minimo: compilar + `vennon <cmd> --help` + 1 teste funcional
- **main.rs alterado?** Obrigatorio atualizar `help.rs` (DIRECTIVE no topo do arquivo)
- **Nunca chamar** `deck stow`, `vennon switch` ou `vennon os` de dentro do container
- **Indices de skills**: ao criar/mover skill, atualizar SKILL.md do namespace pai
- **Nao pedir ao usuario para rodar comandos** — se precisar testar algo, encontrar forma de testar autonomamente

### Capacidades disponiveis no container

```bash
# Compilar e testar CLI Rust
nix-shell -p rustc cargo --run \
  "cd /workspace/host/vennon/rust && cargo build --release -p vennon-cli 2>&1 | tail -5"
/workspace/host/vennon/rust/target/release/vennon <cmd>

# Instalar qualquer ferramenta on-the-fly
nix-shell -p <pacote> --run "<cmd>"

# Escrever em self/
# /workspace/self/ e sempre rw nesta sessao
```

### Output padrao ao terminar upgrade

```
PRONTO: <nome da feature>

tipo:     cli | agent | skill | hook | script
branch:   feat/vennon-<feature>      (N/A para mudancas em self/)
arquivos: lista dos arquivos modificados

testado:
  - bash -n: OK em todos os .sh
  - vennon <cmd> --help: output correto
  - vennon <cmd> <args>: comportamento esperado

proximo:
  Pedro roda `deck stow` no host para aplicar (mudancas CLI/docker)
  OU merge do branch via /commit-push-pr
```
