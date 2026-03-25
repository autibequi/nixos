---
name: coruja/front-student
description: "Skill composta do front-student (Nuxt 2) — app do aluno da Estrategia. Indice das sub-skills de implementacao. Carregar quando o repo ativo for front-student."
---

# front-student — Skill Composta

Skill indice do front-student (Nuxt 2). Roteie para a sub-skill correta conforme a etapa de trabalho.

## Sub-skills

| Sub-skill | Quando usar |
|---|---|
| `front-student/make-feature` | **Ponto de entrada principal** — orquestra service→component→page por modulo |
| `front-student/service` | Criar/modificar service (axios, API calls) |
| `front-student/route` | Criar/modificar rota (Nuxt pages/modules) |
| `front-student/component` | Criar/modificar componente Vue |
| `front-student/page` | Criar/modificar pagina Nuxt |
| `front-student/inspector` | Inspecao de codigo existente no front-student |

## Stack

- Nuxt 2 (SSR + SPA)
- Vue 2
- Vuex (state management por modulo)
- Axios (HTTP client com plugin Nuxt)
- Jest + @vue/test-utils (testes)
- Arquitetura modular: `modules/<nome>/` com pages, components, services
