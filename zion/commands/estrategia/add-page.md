# Page — BO Container ou Front Student

Cria ou modifica page num dos frontends.

## Entrada
- `$ARGUMENTS`: `bo: <descrição>` ou `front: <descrição>`

## Roteamento

| Prefix | Agente | Framework | Tipos |
|--------|--------|-----------|-------|
| `bo:` | BoContainer | Vue 2 | list, form, detail, composite |
| `front:` | FrontStudent | Nuxt 2 | — |

Se não houver prefix → perguntar: "bo ou front?"

## Instruções

```
Agent subagent_type=<Agente> prompt="Execute o skill page para: <descrição>"
```
