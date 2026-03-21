# Go Test Monolito

Roda, analisa e debugga testes no monolito Go.

## Entrada
- `$ARGUMENTS`: app name, file path, test function, "auto" (detecta da branch), ou "coverage <app>"

## Instruções
Spawne o agente **Coruja** com o skill `go-test`:
```
Agent subagent_type=Coruja prompt="Execute o skill go-test para: $ARGUMENTS"
```
