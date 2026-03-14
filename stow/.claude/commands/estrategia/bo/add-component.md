# Component BO Container

Cria ou modifica UI component no bo-container Vue 2.

## Entrada
- `$ARGUMENTS`: descrição do component

## Instruções
Spawne o agente **BoContainer** com o skill `component`:
```
Agent subagent_type=BoContainer prompt="Execute o skill component para: $ARGUMENTS"
```
