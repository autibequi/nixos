---
name: monolito
description: Skill composta do monolito Go (Estrategia) — indice das sub-skills de implementacao + ferramentas de suporte (grafana para debug, linux para ambiente, goodpractices para qualidade). Carregar quando o repo ativo for o monolito.
---

# Monolito — Skill Composta

Skill indice do monolito. Roteie para a sub-skill correta conforme a etapa de trabalho.

## Sub-skills de implementacao

| Skill | Quando usar |
|---|---|
| `monolito/make-feature` | **Ponto de entrada principal** — orquestra todas as etapas na ordem certa |
| `monolito/go-migration` | Criar migration SQL (coluna/tabela nova) |
| `monolito/go-repository` | Entity GORM + interface de repo + implementacao |
| `monolito/go-service` | Interface de servico + impl + wiring + testes |
| `monolito/go-handler` | Handler HTTP + swagger + registro de rota |
| `monolito/go-worker` | Worker SQS + jobtracking |
| `monolito/go-test` | Testes unitarios e integracao |
| `monolito/go-inspector` | Inspecao/analise de codigo existente |

## Ferramentas de suporte

### grafana — debug e observabilidade

Carregar `estrategia/grafana` quando:
- Investigar bug em producao ou sandbox
- Verificar saude apos deploy
- Buscar logs por endpoint, user_id, handler

Datasources do monolito:
- **API server (ECS):** CloudWatch → `/ecs/backend-prod` (erros, panics)
- **Worker SQS (K8s):** Loki → `{app="monolito-worker"}` (zerolog JSON)
- **Dashboard principal:** ECS Logs UID `cehsqeou8rtvke`

### linux — ambiente local

Carregar skill `linux` quando:
- Problemas com o ambiente Docker local (`zion docker run monolito`)
- Questoes de rede, disco, processos, recursos do host
- Conflito de portas, volumes corrompidos, permissoes

### goodpractices — qualidade de codigo

Auto-ativa em qualquer trabalho de implementacao. Reforcar quando:
- Revisar PR do monolito
- Code review de servicos Go
- Verificar patterns de service/handler/repo antes de criar novo

## Stack tecnico

- Go 1.24.4, CGO_ENABLED=1, -tags musl (librdkafka)
- `go.work` workspace com modulos filhos
- Entrypoints: `./cmd/server/main.go` (porta 4004), `./cmd/worker/main.go`
- Arquitetura: apps de dominio → services → repositories → handlers (BO/BFF)
- ORM: GORM + pgx (PostgreSQL)
- Cache: Redis
- Mensageria: SQS (workers), Kafka (search/debezium)
- Logs: zerolog JSON → CloudWatch (ECS) / Loki (K8s)
- Health: `GET /health`
- 6 verticais: concursos, medicina, oab, vestibulares, militares, carreiras-juridicas

## Regras que nunca mudam

- Logica de negocio **sempre** no app de dominio, nunca no BFF/BO
- Handler **sempre** em `bo/`, `bff/` ou `bff_mobile/`
- Servicos de outros apps acessados via `apps.Container`, nunca seus repos diretamente
- Wiring de cada camada feito **antes** de avancar para a proxima
- `go build ./...` + `golangci-lint run` + `make test-<app>` antes de qualquer commit

## Contexto de ambiente local

Ver skill `container-fy` para levantar o monolito localmente via `zion docker`.

Erros nao-criticos conhecidos:
- `ERRO no Client Coruja-AI` — env faltando, sobe normal
- `Falha ao realizar parse da chave privada para assinar cloudfront` — env faltando
- `Toggler: unexpected end of JSON input` — bate ~1min, usa cache, ok
