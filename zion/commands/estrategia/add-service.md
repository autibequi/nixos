# Service — BO Container ou Front Student

Cria ou modifica API service num dos frontends.

## Entrada
- `$ARGUMENTS`: `bo: <descrição>` ou `front: <descrição>`

## Roteamento

| Prefix | Agente | Framework |
|--------|--------|-----------|
| `bo:` | BoContainer | Vue 2 |
| `front:` | FrontStudent | Nuxt 2 |

Se não houver prefix → perguntar: "bo ou front?"

## Instruções

```
Agent subagent_type=<Agente> prompt="Execute o skill service para: <descrição>"
```
