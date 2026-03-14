# Service BO Container

Cria ou modifica API service no bo-container Vue 2.

## Entrada
- `$ARGUMENTS`: descrição do service ou endpoint

## Instruções
Spawne o agente **BoContainer** com o skill `service`:
```
Agent subagent_type=BoContainer prompt="Execute o skill service para: $ARGUMENTS"
```
