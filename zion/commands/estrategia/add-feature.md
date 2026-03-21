# Feature — BO Container ou Front Student

Implementa feature completa num dos frontends.

## Entrada
- `$ARGUMENTS`: `bo: <descrição>` ou `front: <descrição>`

## Roteamento

Extrair target da primeira palavra:

| Prefix | Agente | Framework | Fluxo |
|--------|--------|-----------|-------|
| `bo:` | Coruja | Vue 2 | service → route → component → page |
| `front:` | Coruja | Nuxt 2 | service → component → page |

Se não houver prefix → perguntar: "bo ou front?"

## Instruções

```
Agent subagent_type=<Agente> prompt="Execute o skill make-feature para: <descrição>"
```
