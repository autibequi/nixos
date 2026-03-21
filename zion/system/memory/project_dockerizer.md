---
name: Dockerizer — estado atual
description: Sistema zion docker run/install/logs para monolito e outros serviços estratégia
type: project
---

Sistema de dockerização versionado em `/zion/containers/<service>/` (montado do nixos do host).

**Why:** User quer levantar monolito/bo-container/front-student via `zion docker run <service>` sem precisar ir ao host manualmente. Agente lê logs em `/workspace/logs/docker/<service>/service.log`.

## bo-container — detalhes técnicos

- Node 14 Alpine, Quasar 1.x + Vue 2
- `npm install` durante `docker compose build` (sem `zion docker install` separado)
- SSH agent do host via `--mount=type=ssh` no Dockerfile (para `frontend-libs` git+ssh)
- `NPM_TOKEN` como build arg para `@estrategiahq/*` packages (GitHub Package Registry)
- Dev server HTTPS em `:9090` (hardcoded no quasar.conf.js)
- `LOCAL_BO_CONTAINER_HOST=0.0.0.0` para bind em todas interfaces
- Hot-reload: bind mount de `${BO_CONTAINER_DIR}:/app` + volume anônimo em `/app/node_modules`
- Sem deps compose (sem postgres/redis)
- Para atualizar node_modules: `zion docker flush bo-container && zion docker run bo-container`

**How to apply:** Quando falar de docker, containers, ou levantar serviços da estratégia — este sistema já existe e está funcionando.

## Estrutura de arquivos por serviço (/zion/containers/monolito/)

- `Dockerfile` — multi-stage Go build (golang:1.24.4-alpine → alpine runtime)
- `Dockerfile.debug` — mesmo build + `-gcflags="all=-N -l"` + dlv, runtime usa `golang:1.24.4-alpine` (tem /go/bin/dlv)
- `docker-compose.yml` — app na porta 4004, dlv na 2345, rede nixos_default externa
- `docker-compose.debug.yml` — override: usa Dockerfile.debug + SYS_PTRACE + apparmor:unconfined
- `docker-compose.deps.yml` — postgres 16, redis 7, localstack (SQS/S3)
- `docker-compose.worker.yml` — worker separado
- `env/sand.env`, `env/local.env`, `env/qa.env`, `env/prod.env`
- `init/01_init_db.sql` — CREATE EXTENSION uuid-ossp

## CLI commands

- `zion docker run <service> [--env=sand] [--detach] [--debug]` — levanta + mostra logs
- `zion docker stop <service>`
- `zion docker logs <service> [-f] [--tail=100]`
- `zion docker status [service]`
- `zion docker shell <service> [container]`
- `zion docker restart <service>`
- `zion docker flush <service>`
- `zion docker install <service>`

## Monolito — detalhes técnicos

- Go 1.24.4, CGO_ENABLED=1, -tags musl (librdkafka)
- Entrypoints: `./cmd/server/main.go` (porta 4004) e `./cmd/worker/main.go`
- `go.work` workspace com módulos filhos
- Vendor via `go work vendor` (gerado por `zion docker install`)
- Health: GET /health
- 6 verticais: concursos, medicina, oab, vestibulares, militares, carreiras-juridicas

## Monolito — erros conhecidos no ambiente local (não críticos)

- `ERRO no Client Coruja-AI nenhum endpoint configurado` — env faltando, server sobe normal
- `Falha ao realizar parse da chave privada para assinar cloudfront` — env faltando, não bloqueia boot
- `Toggler: unexpected end of JSON input` — bate a cada ~1min, usa cache, não critico

## Debug remoto (zion docker run monolito --debug)

- Dockerfile.debug: build com `-gcflags="all=-N -l"` + `/go/bin/dlv exec ./server --headless --listen=:2345 --api-version=2 --accept-multiclient --continue`
- docker-compose.debug.yml: SYS_PTRACE + apparmor:unconfined (obrigatório para dlv funcionar em Docker)
- Porta 2345 já exposta no docker-compose.yml base
- launch.json do monolito: `[DOCKER] Attach to monolito` — request=attach, mode=remote, port=2345, substitutePath workspaceFolder→/go/app
- dlv binário fica em `/go/bin/dlv` na imagem golang:alpine (NÃO /root/go/bin/dlv)
- --continue exige --accept-multiclient obrigatoriamente

## Logs — localização

- `/workspace/logs/docker/monolito/service.log` — logs do servidor
- `/workspace/logs/docker/monolito/startup.log` — build/startup
- `/workspace/logs/docker/monolito/deps.log` — dependências
- `/workspace/logs/docker/monolito/install.log` — go mod download

(host: `~/.local/share/zion/logs/<service>/`, mount: `~/.local/share/zion/logs` → `/workspace/logs/docker`)

## docker_run.sh — comportamento

- Logger persistente: `nohup docker compose logs -f --no-log-prefix > service.log &`
- `--no-log-prefix` adicionado em docker_run.sh (linha 83) e docker_logs.sh (linha 18)
- Sem --no-log-prefix, cada linha vinha prefixada com `zion-dk-monolito-app  | `
