# Handler Monolito

Cria ou modifica HTTP handler (endpoint) no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do handler, endpoint, ou método

## Instruções
Spawne o agente **Monolito** com o skill `go-handler`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-handler para: $ARGUMENTS"
```
