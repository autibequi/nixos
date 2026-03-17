# Page BO Container

Cria ou modifica Vue page no bo-container.

## Entrada
- `$ARGUMENTS`: descrição da page (list, form, detail, composite)

## Instruções
Spawne o agente **BoContainer** com o skill `page`:
```
Agent subagent_type=BoContainer prompt="Execute o skill page para: $ARGUMENTS"
```
