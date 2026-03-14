# Repository Monolito

Cria ou modifica repository no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição do repository ou método

## Instruções
Spawne o agente **Monolito** com o skill `go-repository`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-repository para: $ARGUMENTS"
```
