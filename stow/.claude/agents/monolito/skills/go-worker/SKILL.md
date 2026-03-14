---
name: monolito/go-worker
description: Use when creating, modifying, or refactoring any SQS worker/consumer in the monolito Go codebase — covers handler name registration, message struct, worker handler implementation, event container wiring, PrepareWorker setup, and job tracking integration. Applies to new workers, changing worker logic, and updating message handling or job tracking.
---

# Estrategia Go Worker/Consumer Pattern

## Templates

Antes de executar, ler os templates completos com os patterns de codigo:

| Arquivo | Conteudo |
|---|---|
| `templates/handler.md` | EventHandler struct, HandleEvento, HandleEventoDLQ, WrapHandler alternativo |
| `templates/service.md` | Service que cria job + envia mensagens SQS (com RequestsCount dinamico) |
| `templates/wiring.md` | EventContainer, PrepareWorker, config SQS, callback DLQ |

## Overview

Workers consomem mensagens SQS de forma assincrona. O binario `cmd/worker/main.go` roda separado do HTTP server. Cada worker handler e registrado por nome (`AddNamedHandler`) e mapeado a uma fila SQS via config YAML.

**Regra fundamental:** a criacao do registro de job (jobtracking) acontece **sempre no service** que envia as mensagens, **nunca** no handler HTTP nem no worker handler. O service e quem orquestra: cria o job -> envia N mensagens com `job_id` -> o wrapper do worker atualiza contagens automaticamente.

## Anatomia Completa

```
libs/worker/handlers_names.go          # Registro central de nomes de handlers
apps/<app>/structs/<domain>.go         # Struct da mensagem SQS (com job_id)
apps/<app>/internal/services/<svc>/    # Service que cria job + envia mensagens
apps/<app>/internal/handlers/          # EventHandler que consome mensagens
apps/<app>/internal/handlers/event_container.go  # Wiring: registra handlers no sqsWorker
apps/<app>/<app>.go                    # PrepareWorker: instancia container e chama Init
configuration/config_sqs.yaml          # Mapeamento handler -> fila SQS
```

## Passo 1 — Registrar nome do handler

Adicionar o nome em `libs/worker/handlers_names.go`:

```go
var (
    // ... existentes ...

    // <App> — <Descrição>
    MeuNovoHandlerName    = "<App>.MeuNovoHandler"
    MeuNovoHandlerNameDLQ = "<App>.MeuNovoHandlerDLQ"  // só se precisar de DLQ
)
```

**Convenção de nomes:**
- Formato: `<App>.<Ação>` (ex: `LDI.PublishCourseItems`, `BO.BulkAction`)
- DLQ: sufixo `DLQ` (ex: `LDI.PublishCourseItemsDLQ`)

## Passo 2 — Criar struct da mensagem SQS

Em `apps/<app>/structs/<domain>.go`:

```go
// MeuNovoMessage é o payload enviado para o worker via SQS.
// OBRIGATÓRIO: campo JobID para integração com jobtracking.
type MeuNovoMessage struct {
    JobID     string `json:"job_id"`
    // ... campos específicos do payload
    ItemID    string `json:"item_id"`
    Action    string `json:"action"`
}
```

**Regra:** o campo `job_id` (snake_case no JSON) é **obrigatório** quando o worker usa `WithJobTracking`. O wrapper extrai `job_id` do body da mensagem automaticamente.

## Passo 3 — Criar o service que envia mensagens (com JobTracking)

O service cria o job, envia N mensagens SQS com `job_id`, e opcionalmente verifica duplicatas antes.

-> Ver pattern completo em `templates/service.md`

## Passo 4 — Adicionar JobType ao jobtracking

Em `apps/jobtracking/structs/job_search.go`, adicionar a constante:

```go
const (
    // ... existentes ...

    // <App>
    MEU_NOVO_JOB_TYPE JobType = "MEU_NOVO_JOB_TYPE"
)
```

## Passo 5 — Criar o worker handler

O handler deserializa o payload SQS e delega ao service. O DLQ handler retorna nil (o wrapper cuida do tracking). Alternativa com `WrapHandler` para handlers simples sem JobTracking.

-> Ver pattern completo em `templates/handler.md`

## Passo 6 — Wiring no EventContainer

O EventContainer registra handlers no sqsWorker via `AddNamedHandler`, com ou sem `WithJobTracking`. Inclui variante sem JobTracking para handlers simples.

-> Ver pattern completo em `templates/wiring.md`

## Passo 7 — PrepareWorker no app principal

Instancia o EventContainer e chama Init. Se o app ja tem `PrepareWorker`, adicionar o novo handler ao container existente. Se nao tem, criar e registrar no `cmd/worker/main.go`.

-> Ver pattern completo em `templates/wiring.md`

## Passo 8 — Configurar fila SQS

Mapear o named handler na fila SQS apropriada em `configuration/config_sqs.yaml`.

-> Ver pattern completo em `templates/wiring.md`

## JobTracking — Fluxo Automático

```
Service cria Job (RequestsCount=N)
    │
    ├── Envia msg 1 (job_id=xxx) ──► Worker processa ──► WithJobTracking incrementa success/failure
    ├── Envia msg 2 (job_id=xxx) ──► Worker processa ──► WithJobTracking incrementa success/failure
    └── Envia msg N (job_id=xxx) ──► Worker processa ──► WithJobTracking incrementa success/failure
                                                              │
                                            Quando successes+failures == requests
                                                              │
                                                     Status = "completed"
```

**Status é calculado automaticamente** a partir dos counts:
- `started`: RequestsCount == 0
- `running`: Requests > (Successes + Failures)
- `completed`: Requests == (Successes + Failures) e Requests > 0
- `failed`: Failures > 0
- `stale`: Running por mais de 24h sem atualização

## Checklist Obrigatório

- [ ] Nome do handler em `libs/worker/handlers_names.go`
- [ ] Struct da mensagem com `job_id` em `apps/<app>/structs/`
- [ ] JobType em `apps/jobtracking/structs/job_search.go`
- [ ] Service cria job + envia mensagens (nunca o handler HTTP)
- [ ] Service trata falha parcial de SQS (continue, não abort) e marca job como failed se falha total
- [ ] Worker handler em `apps/<app>/internal/handlers/<domain>/worker.go`
- [ ] EventContainer usa `addHandler` (com sqsMiddleware), NUNCA `workerutils.AddNamedHandler` direto
- [ ] PrepareWorker chamado em `cmd/worker/main.go`
- [ ] Handler mapeado na fila SQS em `configuration/config_sqs.yaml`
- [ ] `make test-<app>` passa
- [ ] `golangci-lint run` passa

## Regras de Ouro

| Regra | Detalhe |
|---|---|
| Job criado no SERVICE | Nunca no handler HTTP, nunca no worker handler |
| `job_id` em toda mensagem | Campo obrigatório no JSON quando usa WithJobTracking |
| Handler sem lógica | Deserializa → delega ao service → retorna erro |
| Não combinar WrapHandler + WithJobTracking | Ambos fazem unmarshal; usar um ou outro |
| DLQ handler vazio | Apenas `return nil` — o wrapper cuida do tracking |
| Callback de falha opcional | Usar para notificar bots/alertas quando job falha |
| Vertical via appcontext | `appcontext.GetVertical(ctx)` para indexar service maps |
| SEMPRE usar `addHandler` | Nunca chamar `workerutils.AddNamedHandler` direto — perde sqsMiddleware (tracing, monitoring) |
| Loop SQS resiliente | Falha de 1 envio não aborta os restantes. `continue` + contar falhas |
| Job zumbi → SetStatus failed | Se todos envios SQS falharem, marcar job como `failed` |

## Erros Comuns

- **Criar job no handler HTTP**: move para o service — o handler HTTP deve apenas chamar `service.MeuProcessoAsync()`
- **Esquecer job_id na mensagem**: o wrapper loga "Message without JobID" e falha
- **Usar WrapHandler com WithJobTracking**: double unmarshal, comportamento indefinido
- **Não registrar na config SQS**: handler registrado mas nunca recebe mensagens
- **RequestsCount errado**: se enviar 10 mensagens mas criar job com RequestsCount=5, status fica "inconsistent"
- **Chamar `workerutils.AddNamedHandler` diretamente ao invés de `addHandler`**: pula o `sqsMiddleware` que injeta NewRelic tracing, K8S context e monitoring. SEMPRE usar o helper `addHandler` definido no `Init`
- **Abortar loop SQS na primeira falha**: se o loop de envio retorna no primeiro erro, os items restantes nunca são enfileirados mas o job já foi criado com RequestsCount=N. Usar `continue` e coletar falhas
- **Job zumbi por falha total de SQS**: se TODOS os envios falharem, o job fica com status "started" eternamente. Marcar como `failed` via `SetStatus` quando `failedCount == len(items)`
