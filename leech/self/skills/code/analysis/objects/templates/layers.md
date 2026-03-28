---
name: code/analysis/objects/layers
description: Regras de mapeamento path→layer por repositório para a skill code/analysis/objects
---

# Regras Path → Layer

## monolito (Go)

| Pattern de path | Layer | Observações |
|---|---|---|
| `apps/bff/*/handlers/` ou `apps/bff/main/` | Handlers | Extrair `@Router` e método HTTP |
| `apps/bo/*/` com arquivo `*.go` no nível | Handlers | BO handlers |
| `services/` | Services | Extrair nome da func exportada |
| `repositories/` | Repositories | Extrair nome da func exportada |
| `workers/` ou `handlers/*/worker.go` | Workers | Extrair nome do handler |
| `structs/` ou `types/` | Structs | |
| `mocks/` | Mocks | Agrupar em Tests/Mocks |
| `*_test.go` | Tests | Agrupar em Tests/Mocks |
| `migration/` ou `migrations/` | Migrations | Mostrar só nome do arquivo |
| `*.sql` | Migrations | |

**Detecção de rota Go:**
```
grep -m1 '@Router' <file>
# Exemplo: // @Router /mci/my-courses/slug/:slug/toc [GET]
# Extrair: /mci/my-courses/slug/:slug/toc  GET
```

## bo-container (Vue/JS)

| Pattern de path | Layer |
|---|---|
| `pages/` | Pages |
| `components/` | Components |
| `services/` | Services |
| `router/` ou `routes/` | Routes |
| `store/` | Store |
| `composables/` | Composables |
| `utils/` | Utils |
| `*.spec.js` ou `__tests__/` | Tests |

## front-student (Vue/JS/Nuxt2)

| Pattern de path | Layer |
|---|---|
| `pages/` | Pages |
| `modules/*/containers/` | Containers |
| `modules/*/components/` | Components |
| `modules/*/composables/` | Composables |
| `modules/*/services/` | Services |
| `modules/*/types/` | Types |
| `modules/*/store/` | Store |
| `composables/` (raiz) | Composables |
| `services/` (raiz) | Services |
| `types/` (raiz) | Types |
| `*.spec.js` ou `__tests__/` | Tests |

## Ordem de exibição das camadas

Para monolito:
1. Handlers
2. Services
3. Repositories
4. Workers
5. Structs
6. Migrations
7. Tests/Mocks

Para bo-container:
1. Pages
2. Components
3. Services
4. Routes
5. Store
6. Tests

Para front-student:
1. Pages
2. Containers
3. Components
4. Composables
5. Services
6. Types
7. Store
8. Tests
