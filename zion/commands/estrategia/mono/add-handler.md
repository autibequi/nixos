# Handler Monolito

Cria ou modifica HTTP handler (endpoint) no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do handler, endpoint, ou método

## Instruções
Spawne o agente **Coruja** com o skill `go-handler`:
```
Agent subagent_type=Coruja prompt="Execute o skill go-handler para: $ARGUMENTS"
```
