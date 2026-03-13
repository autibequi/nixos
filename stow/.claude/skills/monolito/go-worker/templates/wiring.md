# Template: EventContainer Wiring + PrepareWorker + SQS Config

## EventContainer (wiring de handlers)

Em `apps/<app>/internal/handlers/event_container.go` (criar se nao existir):

```go
package handlers

import (
    "monolito/apps"
    "monolito/apps/jobtracking"
    meudomain "monolito/apps/<app>/internal/handlers/<domain>"
    "monolito/libs/utils/workerutils"
    handlerNames "monolito/libs/worker"

    "github.com/estrategiahq/backend-libs/spacesbot"
    "github.com/estrategiahq/backend-libs/sqs/sqsworker"
)

type EventContainer struct {
    MeuDomain     *meudomain.EventHandler
    appsContainer *apps.Container
    errorBot      spacesbot.SpacesBot
}

func NewEventHandlerContainer(apps *apps.Container, errorBot spacesbot.SpacesBot) *EventContainer {
    return &EventContainer{
        MeuDomain:     meudomain.NewEventHandler(apps),
        appsContainer: apps,
        errorBot:      errorBot,
    }
}

func (ec *EventContainer) Init(sqsWorker *sqsworker.Worker) {
    // Handler com JobTracking
    workerWrapper := jobtracking.NewWorkerWrapper(*ec.appsContainer)

    workerutils.AddNamedHandler(sqsWorker,
        handlerNames.MeuNovoHandlerName,
        workerWrapper.WithJobTracking(ec.MeuDomain.HandleMeuNovoEvento),
    )

    // DLQ handler (opcional — só se precisar de tratamento de falha)
    workerutils.AddNamedHandler(sqsWorker,
        handlerNames.MeuNovoHandlerNameDLQ,
        workerWrapper.WithJobTrackingDLQ(
            ec.MeuDomain.HandleMeuNovoEventoDLQ,
            ec.NotifyMeuNovoEventoFailure,  // callback de falha
        ),
    )
}
```

### Sem JobTracking (handlers simples)

```go
func (ec *EventContainer) Init(sqsWorker *sqsworker.Worker) {
    // Handler simples — sem job tracking
    workerutils.AddNamedHandler(sqsWorker, handlerNames.MeuHandlerSimples,
        workerutils.WrapHandler(ec.MeuDomain.HandleSimples))
}
```

## PrepareWorker

Em `apps/<app>/<app>.go`, adicionar ou modificar `PrepareWorker`:

```go
func PrepareWorker(sqsWorker *sqsworker.Worker, clients clients.Clients, appsContainer *apps.Container, errorBot spacesbot.SpacesBot) {
    handlers := handlers.NewEventHandlerContainer(appsContainer, errorBot)
    handlers.Init(sqsWorker)
}
```

Se o app **ja tem** `PrepareWorker`, apenas adicionar o novo handler ao container existente.

Se o app **nao tem** `PrepareWorker`, criar a funcao e registrar no `cmd/worker/main.go`:

```go
// cmd/worker/main.go — adicionar a chamada
<app>.PrepareWorker(sqsWorker, clients, appsContainer, errorBot)
```

## Configuracao da fila SQS

Em `configuration/config_sqs.yaml`, adicionar o named handler na fila apropriada:

```yaml
sandbox:
  sqs:
    - name: async-jobs
      url: https://sqs.us-east-1.amazonaws.com/...
      named-handlers:
        - name: "<App>.MeuNovoHandler"     # mesmo nome de handlers_names.go
        - name: "<App>.MeuNovoHandlerDLQ"  # se tiver DLQ
```

## Callback de Falha (DLQ)

Quando o handler de DLQ e acionado, o wrapper chama um callback opcional:

```go
func (ec *EventContainer) NotifyMeuNovoEventoFailure(ctx context.Context, job jobStructs.Job) error {
    if job.Status == jobStructs.StatusFailed {
        msg := fmt.Sprintf("[<App>] Falha ao processar job %s. Erros: %d", job.ID, job.ErrorsCount)
        if err := ec.errorBot.SendMessage(msg); err != nil {
            elogger.Error(ctx).Err(err).Msg("Erro ao enviar mensagem para o bot")
        }
    }
    return nil
}
```
