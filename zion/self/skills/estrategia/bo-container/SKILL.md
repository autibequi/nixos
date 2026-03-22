---
name: estrategia/bo-container
description: "Skill composta do bo-container (Vue 2 + Quasar) — admin panel da Estrategia. Indice das sub-skills de implementacao. Carregar quando o repo ativo for bo-container."
---

# bo-container — Skill Composta

Skill indice do bo-container (Vue 2 + Quasar). Roteie para a sub-skill correta conforme a etapa de trabalho.

## Sub-skills

| Sub-skill | Quando usar |
|---|---|
| `bo-container/make-feature` | **Ponto de entrada principal** — orquestra service→route→component→page |
| `bo-container/service` | Criar/modificar service (axios, API calls) |
| `bo-container/route` | Criar/modificar rota (vue-router) |
| `bo-container/component` | Criar/modificar componente Vue |
| `bo-container/page` | Criar/modificar pagina (layout, container) |
| `bo-container/inspector` | Inspecao de codigo existente no bo-container |

## Stack

- Vue 2 + Quasar Framework
- Vuex (state management)
- Axios (HTTP client com dependency injection)
- Vue Router
- Jest + @vue/test-utils (testes)
