# Template: Worker Handler

## EventHandler (padrão completo)

Em `apps/<app>/internal/handlers/<domain>/worker.go`:

```go
package meudomain

import (
    "context"
    "encoding/json"

    "monolito/apps"
    appStructs "monolito/apps/<app>/structs"
    "monolito/libs/appcontext"

    "github.com/estrategiahq/backend-libs/elogger"
    "github.com/estrategiahq/backend-libs/sqs"
)

// EventHandler processa mensagens SQS para <domain>.
type EventHandler struct {
    apps *apps.Container
}

func NewEventHandler(apps *apps.Container) *EventHandler {
    return &EventHandler{apps: apps}
}

// HandleMeuNovoEvento processa uma mensagem do worker.
// O jobtracking wrapper cuida de extrair job_id e atualizar contagens.
func (h *EventHandler) HandleMeuNovoEvento(ctx context.Context, msg sqs.Message) error {
    // 1. Context (vertical, requestID) já setado pelo middleware
    vertical := appcontext.GetVertical(ctx)

    // 2. Deserializar payload
    var payload appStructs.MeuNovoMessage
    if msg.Body != nil {
        if err := json.Unmarshal([]byte(*msg.Body), &payload); err != nil {
            elogger.Error(ctx).Err(err).Msg("HandleMeuNovoEvento: unmarshal failed")
            return err
        }
    } else {
        elogger.Warn(ctx).Msg("HandleMeuNovoEvento: empty body")
        return nil
    }

    // 3. Delegar para o service (toda lógica no service)
    err := h.apps.MinhaApp[vertical].MeuService.ProcessarItem(ctx, payload.ItemID)
    if err != nil {
        elogger.Error(ctx).Err(err).Msg("HandleMeuNovoEvento: processing failed")
        return err
    }

    return nil
}

// HandleMeuNovoEventoDLQ handler para DLQ — apenas registra a falha.
// O wrapper WithJobTrackingDLQ cuida de marcar o job como failed.
func (h *EventHandler) HandleMeuNovoEventoDLQ(ctx context.Context, msg sqs.Message) error {
    return nil
}
```

## Alternativa: WrapHandler (handler simples com generics)

Quando o handler é simples e **não usa JobTracking**, pode-se usar `WrapHandler` para auto-unmarshal do payload:

```go
// Usar WrapHandler para auto-unmarshal do payload
workerutils.AddNamedHandler(sqsWorker, handlerName,
    workerutils.WrapHandler(func(ctx context.Context, payload appStructs.MeuNovoMessage) error {
        vertical := appcontext.GetVertical(ctx)
        return apps.MinhaApp[vertical].MeuService.ProcessarItem(ctx, payload.ItemID)
    }),
)
```

**ATENÇÃO:** `WrapHandler` e `WithJobTracking` ambos fazem unmarshal do body. Quando usar `WithJobTracking`, o handler recebe `sqs.Message` (não o payload tipado) — o handler deve fazer unmarshal manualmente. Não combinar `WrapHandler` com `WithJobTracking`.
