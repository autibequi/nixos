---
name: estrategia/platform-context
description: "Contexto compartilhado dos 3 repos da Estrategia — stacks, design system, multi-tenant, convencoes de comunicacao. Carregar quando precisar de visao geral da plataforma."
---

# Estrategia — Contexto da Plataforma

Contexto compartilhado entre os 3 repositorios da plataforma Estrategia.

## Os tres repositorios

| Repo | Stack | Responsabilidade |
|------|-------|-----------------|
| **monolito** | Go 1.24, GORM, pgx, zerolog | API REST, handlers, services, repositories, workers, migrations |
| **bo-container** | Vue 2, Options API, Quasar, hash routing | Interface administrativa (backend office) |
| **front-student** | Nuxt 2, Options API, SSR | Portal do aluno |

```
/workspace/estrategia/monolito/       — ou /home/claude/projects/estrategia/monolito/
/workspace/estrategia/bo-container/
/workspace/estrategia/front-student/
```

## Convencoes compartilhadas

### Multi-tenant (verticais)

Toda a plataforma e multi-tenant por vertical:
- **Fronts**: header `X-Vertical` em toda chamada HTTP
- **Monolito**: `appcontext.GetVertical(ctx)` para ler a vertical do request
- 6 verticais: concursos, medicina, oab, vestibulares, militares, carreiras-juridicas

### Design System

Usar `@estrategiahq/coruja-web-ui` nos fronts antes de criar componente custom. O design system cobre: botoes, inputs, modais, tabelas, cards, layout.

### Service pattern (fronts)

Mesma estrutura de classe axios nos dois fronts:
- Dependency injection do axios instance
- Metodos como `axiosFoo()` retornam promises
- Intercepadores de auth e error handling centralizados

### Comunicacao entre repos

- Repos comunicam **exclusivamente via API** — nunca compartilham codigo diretamente
- monolito expoe endpoints → fronts consomem via services
- Nunca importar modulo de um front no outro
