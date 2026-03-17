# Service Monolito

Cria ou modifica service no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do service ou método

## Instruções
Spawne o agente **Monolito** com o skill `go-service`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-service para: $ARGUMENTS"
```
