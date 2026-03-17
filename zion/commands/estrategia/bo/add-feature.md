# Feature BO Container

Implementa feature completa no bo-container Vue 2 (service → route → component → page).

## Entrada
- `$ARGUMENTS`: descrição da feature

## Instruções
Spawne o agente **BoContainer** com o skill `make-feature`:
```
Agent subagent_type=BoContainer prompt="Execute o skill make-feature para: $ARGUMENTS"
```
