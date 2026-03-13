# Template: Service com JobTracking

## Service completo (cria job + envia mensagens SQS)

**REGRA CRITICA:** O registro do job acontece **no service**, nunca no handler HTTP. O service:
1. Verifica se ja existe job em execucao (opcional, para evitar duplicatas)
2. Cria o job via `jobTrackingService.JobTracking.Create()`
3. Envia N mensagens SQS, cada uma com o `job_id` do job criado
4. Trata falhas parciais de envio SQS (continua loop, nao aborta)
5. Se TODOS envios falharem, marca job como `failed` para evitar job zumbi

```go
package meuservice

import (
    "context"
    "encoding/json"
    "fmt"

    "monolito/apps/jobtracking/structs"
    appStructs "monolito/apps/<app>/structs"
    "monolito/libs/appcontext"
    handlerNames "monolito/libs/worker"

    "github.com/estrategiahq/backend-libs/elogger"
)

func (s serviceImpl) MeuProcessoAsync(ctx context.Context, items []appStructs.MeuItem) (structs.Job, error) {
    // 1. (Opcional) Verificar se já existe job em execução para os mesmos IDs
    ids := make([]string, len(items))
    for i, item := range items {
        ids[i] = item.ID
    }

    existingJobs, err := s.jobTrackingService.JobTracking.Search(ctx, structs.JobSearch{
        JobType:    structs.MEU_NOVO_JOB_TYPE,  // definir em jobtracking/structs/job_search.go
        RelatedIDs: ids,
        Status:     structs.StatusRunning,
    })
    if err != nil {
        elogger.ErrorErr(ctx, err).Msg("meuService.MeuProcessoAsync.JobTracking.Search")
        return structs.Job{}, err
    }
    if len(existingJobs) > 0 {
        return structs.Job{}, structs.ErrJobAlreadyExists
    }

    // 2. Criar o job ANTES de enviar mensagens
    job, err := s.jobTrackingService.JobTracking.Create(ctx, structs.Job{
        JobType:       structs.MEU_NOVO_JOB_TYPE,
        RequestsCount: len(items),  // total de mensagens que serão enviadas
        RelatedIDs:    ids,
    }, structs.JobRequest{
        Description: "Descrição curta do processamento",
        Data:        items,  // payload original para auditoria
    })
    if err != nil {
        elogger.ErrorErr(ctx, err).Msg("meuService.MeuProcessoAsync.JobTracking.Create")
        return structs.Job{}, err
    }

    // 3. Enviar uma mensagem por item, cada uma com job_id.
    //    IMPORTANTE: continuar loop em caso de falha parcial — não abortar na primeira.
    //    Se TODOS falharem, marcar job como failed para evitar job zumbi.
    vertical := appcontext.GetVertical(ctx)
    var failedCount int
    for _, item := range items {
        message := appStructs.MeuNovoMessage{
            JobID:  job.ID,
            ItemID: item.ID,
            Action: item.Action,
        }

        payload, err := json.Marshal(message)
        if err != nil {
            elogger.ErrorErr(ctx, err).Msg("meuService.MeuProcessoAsync.json.Marshal")
            failedCount++
            continue
        }

        err = s.sqs.Sender().
            ForNamedHandler(handlerNames.MeuNovoHandlerName).
            WithVertical(vertical).
            WithRequestID(appcontext.RequestID.GetStringValue(ctx)).
            SendMessage(ctx, string(payload))
        if err != nil {
            elogger.ErrorErr(ctx, err).Str("item_id", item.ID).Msg("meuService.MeuProcessoAsync.sqs.Send")
            failedCount++
            continue
        }
    }

    if failedCount > 0 {
        if failedCount == len(items) {
            // Nenhuma mensagem enviada — marca job como failed pra não virar zumbi.
            // Sem isso, o job fica com status "started" eternamente e pode bloquear
            // guards que checam jobs ativos (ex: CheckTocRebuildActive).
            if statusErr := s.jobTrackingService.JobTracking.SetStatus(ctx, job.ID, structs.StatusFailed); statusErr != nil {
                elogger.ErrorErr(ctx, statusErr).Str("job_id", job.ID).Msg("meuService.MeuProcessoAsync.SetStatus failed")
            }
        }
        return job, fmt.Errorf("falha ao enfileirar %d de %d itens", failedCount, len(items))
    }

    return job, nil
}
```

## Alternativa: RequestsCount dinamico

Se o total de mensagens nao for conhecido no momento da criacao do job:

```go
// Criar job sem RequestsCount
job, err := s.jobTrackingService.JobTracking.Create(ctx, structs.Job{
    JobType: structs.MEU_NOVO_JOB_TYPE,
}, structs.JobRequest{
    Description: "Descrição",
    Data:        nil,
})

// Depois de saber o total, atualizar
s.jobTrackingService.JobTracking.IncrementCounts(ctx, job.ID, structs.JobStatusIncrement{
    Requests: totalCalculado,
})
```
