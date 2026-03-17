# Worker Monolito

Cria ou modifica SQS worker/consumer no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do worker ou evento

## Instruções
Spawne o agente **Monolito** com o skill `go-worker`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-worker para: $ARGUMENTS"
```
