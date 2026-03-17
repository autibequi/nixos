# Migration Monolito

Cria ou modifica database migration no monolito Go.

## Entrada
- `$ARGUMENTS`: descrição da migration (tabela, coluna, índice)

## Instruções
Spawne o agente **Monolito** com o skill `go-migration`:
```
Agent subagent_type=Monolito prompt="Execute o skill go-migration para: $ARGUMENTS"
```
