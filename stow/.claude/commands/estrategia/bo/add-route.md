# Route BO Container

Cria ou modifica route no bo-container Vue 2.

## Entrada
- `$ARGUMENTS`: descrição da rota ou path

## Instruções
Spawne o agente **BoContainer** com o skill `route`:
```
Agent subagent_type=BoContainer prompt="Execute o skill route para: $ARGUMENTS"
```
