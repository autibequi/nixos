# Go Inspector Monolito

Inspeção multi-perspectiva de feature chain no monolito.

## Entrada
- `$ARGUMENTS`: PR number, branch, ou "auto" (detecta branch ativa)

## Instruções
Spawne o agente **Monolito** com o skill `go-inspector`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-inspector para: $ARGUMENTS"
```
