# Categorização por Repositório

Tabelas de referência para classificar arquivos modificados/criados em cada repositório.

## Monolito (Go + Echo)

| Categoria | Path pattern | O que extrair |
|---|---|---|
| **Migrations** | `migrations/` ou `*migration*` | Nome da migration, tabelas/colunas afetadas |
| **Entities/Models** | `apps/*/internal/entities/` ou `*/models/` | Structs novas ou campos adicionados — nome da struct e campos com tipos |
| **Repositories** | `apps/*/internal/repositories/` | Interfaces novas ou métodos novos — `NomeMétodo(params) (retorno)` |
| **Services** | `apps/*/internal/services/` | Métodos novos ou modificados — `NomeMétodo(params) (retorno, error)` |
| **Handlers** | `apps/*/internal/handlers/` (exceto `worker/`) | Endpoints: método HTTP + rota + handler function |
| **Workers** | `apps/*/internal/handlers/worker/` | Worker handlers novos ou modificados |
| **Mocks** | `*mock*` ou `*_mock.go` | Apenas listar — não detalhar |
| **Testes** | `*_test.go` | Apenas listar funções de teste novas/modificadas |
| **Config/Outros** | Demais arquivos `.go` | Listar com breve descrição da mudança |

## bo-container (Vue 2 + Quasar 1.x)

| Categoria | Path pattern | O que extrair |
|---|---|---|
| **Services** | `src/modules/*/services/*.js` | Métodos novos ou modificados — `nomeMetodo(params)` + endpoint chamado |
| **Routes** | `src/modules/*/router/index.js` | Rotas adicionadas/modificadas — path + name + componente |
| **Pages** | `src/modules/*/pages/**/*.vue` | Nome da page + props + métodos relevantes do `<script>` |
| **Components** | `src/modules/*/components/**/*.vue` | Nome do componente + props + eventos emitidos |
| **Stores/State** | `src/modules/*/store/**` | Mutations/actions novas |
| **Outros** | Demais arquivos | Listar com breve descrição |

## front-student (Nuxt 2 + Vue 2)

| Categoria | Path pattern | O que extrair |
|---|---|---|
| **Services (root)** | `services/*.js` | Métodos novos — `nomeMetodo(params)` + endpoint chamado |
| **Services (module)** | `modules/*/services/*.js` | Métodos novos — `nomeMetodo(params)` + endpoint chamado |
| **Pages** | `pages/**/*.vue` | Nome da page + layout + middleware + rota implícita (pelo path do arquivo) |
| **Containers** | `modules/*/containers/*.vue` | Nome + métodos de data-fetching + estado gerenciado |
| **Components** | `modules/*/components/**/*.vue` | Nome + props + eventos emitidos |
| **Stores/State** | `store/**` ou `modules/*/store/**` | Mutations/actions novas |
| **Outros** | Demais arquivos | Listar com breve descrição |
