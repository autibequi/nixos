# Repository Monolito

Cria ou modifica repository no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do repository ou método

## Instruções
Spawne o agente **Coruja** com o skill `go-repository`:
```
Agent subagent_type=Coruja prompt="Execute o skill go-repository para: $ARGUMENTS"
```
