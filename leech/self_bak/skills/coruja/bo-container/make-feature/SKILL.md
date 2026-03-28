---
name: bo-container/make-feature
description: Use when implementing, modifying, or refactoring a feature in bo-container — orchestrates bo-container/service, bo-container/route, bo-container/component, and bo-container/page in sequence. Applies to new features, extending existing features, refactoring multi-layer code, and any change spanning service/route/component/page.
---

# bo-container/make-feature: Implementar Feature Completa no bo-container

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

## Inputs Esperados do Orquestrador

| Campo | Tipo | Descrição |
|---|---|---|
| `module` | string | Nome do módulo alvo (ex: `ranking`) |
| `description` | string | O que a feature faz |
| `endpoints` | array | Lista com `{ method, url, payload?, response_shape }` |
| `screen_type` | enum | `list \| form \| detail \| composite` |
| `is_extension` | boolean | `true` = adicionar a feature existente; `false` = feature nova |

## Fluxo de Orquestração

```
0. LER STATE.md → /workspace/home/estrategia/bo-container/STATE.md (posição atual, blockers)
1. EXPLORAR: ler router/index.js, services/, pages/ do módulo alvo
2. bo-container/service   → criar/extender service com os endpoints fornecidos
3. bo-container/route     → registrar rota (SOMENTE se is_extension = false)
4. RESOLVER COMPONENTES → buscar shared/ → Quasar → invocar bo-container/component se necessário
5. bo-container/page      → criar página com screen_type correto, wirando service + componentes
```

### Se `is_extension = true`

Pular steps 3 (bo-container/route) e 5 (bo-container/page). Modificar diretamente:
- O service existente (adicionar métodos)
- A página existente (adicionar modal, drawer, seção, ou nova coluna)

## Regras

- **Nunca** tocar em módulos além do alvo. Se precisar de dado de outro módulo, use serviço de `src/modules/shared/services/` ou crie um lá.
- **Sempre** priorizar componentes de `shared/` antes de criar novos.
- **Não** criar rotas no `src/router/routes.js` global — cada módulo gerencia seu próprio router.
- **Verificação obrigatória antes de qualquer commit:**

  **Passo 1 — lint nos arquivos alterados:**
  ```bash
  npx eslint $(git diff --name-only main -- . | grep '\.vue$\|\.js$' | while read f; do [ -f "$f" ] && echo "$f"; done | tr '\n' ' ')
  ```

  **Passo 2 — auto-fix e re-verificar:**
  ```bash
  npx eslint --fix <arquivos alterados>
  npx eslint <arquivos alterados>
  ```

  **Passo 3 — build:**
  ```bash
  yarn build
  ```

  - [ ] `npx eslint` nos changed files sem erros (warnings são ok)
  - [ ] `yarn build` sem erros
  - [ ] Nenhum erro no console ao acessar as rotas da feature
  - Se alguma verificação falhar: corrigir antes de commitar
- **Atualizar STATE.md** ao concluir: registrar feature implementada, decisões técnicas relevantes, e qualquer blocker encontrado em `/workspace/home/estrategia/bo-container/STATE.md`
- **Reportar ao final** (para o orquestrador):
  - Arquivos criados: lista com paths
  - Arquivos modificados: lista com paths
  - Rotas registradas: path e name
  - Componentes reutilizados: lista
  - Componentes criados: lista com paths

## Referência de Skills Atômicas

- `bo-container/service` — criação/extensão de service
- `bo-container/route` — registro de rota
- `bo-container/component` — criação de componente
- `bo-container/page` — criação de página com padrões de screen

## Como Buscar Componentes Existentes (Step 4 detalhado)

Antes de criar qualquer componente novo, buscar nesta ordem:

1. **`src/modules/shared/components/`** — verificar subdiretórios:
   - `Lists/` (TableItems, SortHeader, Pagination)
   - `Modals/` (BaseModal, delete-confirmation-modal)
   - `Cards/`, `Tabs/`, `Charts/`, `Header/`
   - `search-bar.vue`, `empty-state/`, `toggle/`, `input-text/`, `input-date-time/`, `TextArea/`
2. **Quasar 1.x** — prefixo `Q`:
   - Layout: `QPage`, `QCard`, `QCardSection`, `QSplitter`, `QDrawer`
   - Forms: `QInput`, `QSelect`, `QField`, `QBtn`, `QForm`
   - Data: `QTable` (para tabelas simples), `QList`, `QItem`
   - Feedback: `QDialog`, `QTooltip`, `QBanner`
3. **`@estrategiahq/coruja-web-ui`** — prefixo `C`:
   - `CIcon`, `CSearchBar`, `CDropdownSmall`, `CCard`, `CPaginator`
4. **Criar novo** — somente se nenhuma opção acima atender

## Convenções de Naming

| Tipo | Convenção | Exemplo |
|---|---|---|
| **Componentes** | PascalCase + sufixo descritivo | `RankingModal.vue`, `CourseForm.vue`, `ItemList.vue` |
| **Pages** | PascalCase em pasta própria | `pages/Results/index.vue` |
| **Services** | camelCase, nome da entidade | `ranking.js`, `courseItems.js` |
| **Store modules** | camelCase | `materialsStore/index.js` |
| **Rotas** | kebab-case | `path: 'ranking/results'`, `name: 'ranking-results'` |

Sufixos comuns para componentes: `Modal`, `Form`, `List`, `Card`, `Drawer`, `Filter`, `Header`.

## Convenções Gerais do Projeto

- **Vue 2 Options API** (não usar Composition API exceto com `@vue/composition-api` explicitamente importado)
- **Quasar 1.x** — componentes com prefixo `Q`, ver lista em `quasar.conf.js`
- **Routing hash mode** — URLs como `#/concursos/ranking/results`
- **Vertical nos headers** — `X-Vertical` é injetado automaticamente pelos interceptors axios
- **Auth** — `$loggedUser.getToken()` para o Bearer token, também via interceptor
- **Env vars** — usar `env.API_FOO_URL` de `src/boot/env.js`, não `process.env` direto nos componentes
