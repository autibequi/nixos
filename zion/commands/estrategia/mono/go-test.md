# Go Test Monolito

Roda, analisa e debugga testes no monolito Go.

## Entrada
- `$ARGUMENTS`: app name, file path, test function, "auto" (detecta da branch), ou "coverage <app>"

## Instruções
Spawne o agente **Monolito** com o skill `go-test`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-test para: $ARGUMENTS"
```
