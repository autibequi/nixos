# Review Code Monolito

Code review de PR ou branch no monolito/estratégia.

## Entrada
- `$ARGUMENTS`: PR number, branch, ou descrição do que revisar

## Instruções
Spawne o agente **Coruja** com o skill `review-code`:
```
Agent subagent_type=Coruja prompt="Execute o skill review-code para: $ARGUMENTS"
```
