---
name: bo-container/inspector
description: Inspeção de qualidade e contrato no bo-container. Use para validar features novas, mudanças em services, tratamento de erros de API, e alinhamento de contrato com o backend (monolito). Abrange: services, pages, components, stores, error handling (409, 4xx, 5xx), e padrões Vue 2.
---

# bo-inspector: Inspeção do BO Container

## Quando usar

- Após mudança em services que chamam endpoints do monolito
- Ao adicionar nova rota ou página que consome API
- Para verificar se feature está alinhada com mudanças no backend
- Para validar tratamento de erros novos (ex: 409 de rebuild ativo)

## Estrutura do Projeto

```
src/modules/<módulo>/
  services/        ← chamadas HTTP (axios class)
  pages/           ← entry points (Quasar q-page)
  components/      ← presentational
  containers/      ← smart components com acesso a store/services
  store/           ← Vuex modules
  routes.js        ← definição de rotas do módulo
```

**Base URLs por instância axios:**

| dep | baseURL | Rota backend |
|-----|---------|-------------|
| `axiosBO()` | `API_BO_URL` | `/bo/*` genérico |
| `axiosBff()` | `API_BO_URL` + `X-LDI-Type` | `/ldi/*`, `/trilhas/*` |
| `axiosCursos()` | `API_BO_URL/cursos` | `/bo/cursos/*` |
| `axiosMyDocs()` | `API_BO_URL/materiais` | `/bo/materiais/*` |

## Checklist de Inspeção

### Services (`src/modules/<módulo>/services/*.js`)

- [ ] Classe com `constructor(deps)` — recebe instâncias axios, não as cria
- [ ] Métodos async, sem estado interno
- [ ] Sem headers ou interceptors no service (já configurados no `index.js`)
- [ ] Sem lógica de negócio — apenas chamadas HTTP
- [ ] Nomes de parâmetros em `snake_case` nos query params (`per_page`, não `perPage`)
- [ ] Body de PUT/POST em `snake_case` para bater com as json tags Go do backend

#### Armadilhas de Contrato com o Backend

- **JSON case**: Go `json.Unmarshal` é case-insensitive, mas enviar `PascalCase` do JS para campos `snake_case` Go é smell. Ex: `{ Published: bool }` deveria ser `{ published: bool }`.
- **Campos extras no body**: Go ignora campos extras no unmarshal — enviar spread de objeto grande é ok, mas verificar se nenhum campo sobrescreve validações.
- **Paginação**: backend espera `page`, `per_page`, `all` — verificar se o service mapeia `perPage → per_page`.
- **`include_block_types`**: se o endpoint suportar, verificar se o service passa corretamente como query param boolean (`'true'` string ou `true`).

### Error Handling

- [ ] `getErrorMessage(e)` de `@/modules/core/apiErrors` para mensagens ao usuário
- [ ] `this.$q.notify({ type: 'negative', ... })` para erros
- [ ] **409 de rebuild ativo**: endpoints que ganham `CheckTOCRebuild` no backend retornam 409. O componente deve tratar com mensagem específica ao usuário, não genérica.
- [ ] Tratamento de 409 em: `publishCourse`, `publishItem`, `publishCourseItems`, `put_name`, `put_title`, `updateName`

```javascript
// Padrão correto para 409
try {
  await services.ldi.publishCourse(id, true)
} catch (e) {
  if (e?.response?.status === 409) {
    this.$q.notify({ type: 'warning', message: 'Publicação em andamento, aguarde.' })
    return
  }
  this.$q.notify({ type: 'negative', message: getErrorMessage(e) })
}
```

### Pages e Components

- [ ] `q-page` como wrapper
- [ ] `page-header` para título e ações de topo
- [ ] Loading state enquanto aguarda resposta assíncrona
- [ ] Sem `console.log` ou `debugger`
- [ ] Sem URLs hardcoded (usar service)
- [ ] Props com `type` e `default`
- [ ] Events via `$emit`, não callback props

### Store (Vuex)

- [ ] State inicializado com valores default (não null implícito)
- [ ] Mutations síncronas, actions assíncronas
- [ ] Namespaced (`namespaced: true`)
- [ ] Sem lógica de negócio complexa — delegar ao service

### Jobs Assíncronos (async endpoints)

Quando o endpoint retorna um job (`{ data: { id, status } }`):
- [ ] Frontend salva o `job.id` para polling
- [ ] Existe modal ou feedback de progresso enquanto job está rodando
- [ ] Tratamento de `status: 'failed'` com mensagem ao usuário

## Processo de Inspeção

### 1. Mapear endpoints afetados

```bash
# Listar arquivos de service modificados no diff
git diff main...HEAD --name-only | grep "services/"

# Para cada service modificado, ler o arquivo
```

### 2. Cruzar com backend

Para cada endpoint chamado pelo service:
1. Identificar a URL completa (baseURL + path relativo)
2. Buscar o handler Go correspondente no monolito
3. Comparar: método HTTP, query params, body fields, response shape

### 3. Verificar tratamento de erros novos

Se o backend adicionou `CheckTOCRebuild` (retorna 409), verificar cada caller no bo-container.

### 4. Aplicar checklist por camada

Services → Store → Components → Pages (bottom-up)

## Formato de Output

```markdown
## bo-container — [Feature/Branch]

### Services
- ✅ ALINHADO: `getCourseChapters` — params `page`, `per_page`, `all` corretos
- ⚠️ RISCO: `publishCourse` — envia `{ Published }` (PascalCase), backend espera `published`
- 🔴 QUEBRADO: `getChapters` — campo `chapter_id` renomeado para `id` no backend

### Error Handling
- ❌ FALTANDO: `publishCourse` não trata 409 (rebuild ativo)
- ✅ OK: `publishItem` trata 409 com mensagem adequada

### Jobs Assíncronos
- ✅ `publishCourseItemsBatchAsync` — polling implementado em PreviewCourse
```

## Aprendizados (desta inspeção)

### JSON case-insensitivity no Go é smell
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** `bff.js:324` envia `{ Published: status }` (PascalCase) para endpoint Go com `json:"published"`. Funciona por case-insensitivity mas é frágil e inconsistente.
**O que checar:** Ao inspecionar qualquer service que chama endpoint Go, verificar se campos de body usam `snake_case` (o padrão da API) ou `camelCase`/`PascalCase`.

### Endpoints assíncronos precisam de tratamento explícito de `status: failed`
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** `publishCourseItemsBatchAsync` retorna job com status. Se o job falhar, o frontend precisa exibir erro — não só spinner infinito.
**O que checar:** Todo endpoint `*/async` deve ter tratamento para job `failed`, não só `success`.

### 409 de CheckTOCRebuild precisa de mensagem específica
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** Backend retorna 409 quando há rebuild de TOC ativo. Mensagem genérica de erro confunde o usuário — precisa de "Aguarde a publicação anterior terminar".
**O que checar:** Em features LDI que usam publicação ou edição de itens/capítulos, verificar tratamento de 409 em cada caller.
