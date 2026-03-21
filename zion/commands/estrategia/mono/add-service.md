# Service Monolito

Cria ou modifica service no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do service ou método

## Instruções
Spawne o agente **Coruja** com o skill `go-service`:
```
Agent subagent_type=Coruja prompt="Execute o skill go-service para: $ARGUMENTS"
```
