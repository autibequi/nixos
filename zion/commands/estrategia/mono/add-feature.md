# Feature Monolito

Implementa feature completa no monolito Go (migration → repo → service → handler).

## Entrada
- `$ARGUMENTS`: descrição da feature ou card Jira

## Instruções
Spawne o agente **Coruja** com o skill `make-feature`:
```
Agent subagent_type=Coruja prompt="Execute o skill make-feature para: $ARGUMENTS"
```
