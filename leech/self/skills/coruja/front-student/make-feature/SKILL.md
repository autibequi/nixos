---
name: front-student/make-feature
description: Use when implementing, modifying, or refactoring a feature in front-student — orchestrates front-student/service, front-student/component, and front-student/page in sequence following module architecture. Applies to new features, extending existing features, refactoring multi-layer code, and any change spanning service/component/page.
---

# front-student/make-feature: Implementar Feature Completa no front-student

## Inputs Esperados do Orquestrador

| Campo | Tipo | Descrição |
|---|---|---|
| `module` | string | Nome do módulo alvo (ex: `cast`, `objetivos`) |
| `description` | string | O que a feature faz |
| `endpoints` | array | Lista com `{ method, url, payload?, response_shape }` |
| `needs_page` | boolean | `true` = nova rota Nuxt; `false` = extensão de página existente |
| `is_extension` | boolean | `true` = adicionar a feature existente; `false` = feature nova |

## Fluxo de Orquestração

```
0. LER STATE.md → /workspace/mnt/estrategia/front-student/STATE.md (posição atual, blockers)
1. EXPLORAR: ler modules/<módulo>/services/, components/, containers/, pages/ do módulo alvo
2. front-student/service   → criar/extender service e registrar em services/index.js
3. RESOLVER COMPONENTES:
   - Buscar em @estrategiahq/coruja-web-ui (DesignSystem, prefixo C)
   - Buscar em modules/share/components/
   - Buscar em components/
   - Invocar front-student/component se necessário
4. Criar container em modules/<módulo>/containers/ (se necessário)
5. front-student/page      → criar página Nuxt (SOMENTE se needs_page = true)
```

### Se `is_extension = true`

Não criar nova página. Modificar diretamente:
- O service existente (adicionar métodos)
- O container existente (adicionar lógica, passar novas props)
- O componente existente (adicionar seção, modal, ou comportamento)

## Estrutura de Módulo Padrão

```
modules/<módulo>/
  components/       # componentes presentacionais do módulo
  containers/       # smart containers (data fetching + state)
  services/         # factory functions de API
  store/            # Vuex store module (se necessário)
  mixins/           # Vue mixins (usar com moderação)
  __tests__/        # specs Jest
```

Páginas ficam em `pages/`, **fora** dos módulos — elas importam de `modules/`.

## Regras

- **Nunca** acessar services de outro módulo diretamente — use `this.$services.<service>` que é global.
- **Sempre** priorizar componentes do DesignSystem e `modules/share/` antes de criar novos.
- **Rotas são file-based** — apenas criar/mover arquivo em `pages/` para criar uma rota.
- **asyncData** para dados que precisam de SSR; `mounted` para client-only.
- **Containers** são o lugar certo para lógica de negócio — não colocar em páginas.
- **Verificação obrigatória antes de qualquer commit:**

  **Passo 1 — lint nos arquivos alterados:**
  ```bash
  npx eslint --ext .js,.vue $(git diff --name-only main -- . | grep '\.vue$\|\.js$' | while read f; do [ -f "$f" ] && echo "$f"; done | tr '\n' ' ')
  ```

  **Passo 2 — auto-fix e re-verificar:**
  ```bash
  npx eslint --ext .js,.vue --fix <arquivos alterados>
  npx eslint --ext .js,.vue <arquivos alterados>
  ```

  **Passo 3 — build:**
  ```bash
  yarn build
  ```

  - [ ] `npx eslint` nos changed files sem erros (warnings são ok)
  - [ ] `yarn build` sem erros
  - [ ] Nenhum erro no console ao navegar pelas rotas da feature
  - Se alguma verificação falhar: corrigir antes de commitar
- **Atualizar STATE.md** ao concluir: registrar feature implementada, decisões técnicas relevantes, e qualquer blocker encontrado em `/workspace/mnt/estrategia/front-student/STATE.md`
- **Reportar ao final** (para o orquestrador):
  - Arquivos criados: lista com paths
  - Arquivos modificados: lista com paths
  - Rotas criadas: path e nome do arquivo
  - Componentes reutilizados: lista
  - Componentes criados: lista com paths

## Referência de Skills Atômicas

- `front-student/service` — criação/extensão de service
- `front-student/component` — resolução/criação de componente ou container
- `front-student/page` — criação de página Nuxt com padrões corretos

## Onde Fica a Lógica? (Page vs Container vs Component)

| Responsabilidade | Onde | Exemplo |
|---|---|---|
| Layout, `asyncData`, `head()`, middleware | **Page** (`pages/`) | Fetch SSR, layout selection, meta tags |
| API calls, estado local, event handling, navegação | **Container** (`modules/<mod>/containers/`) | `this.$services`, `this.$router.push`, `this.$store` |
| Renderização, props, $emit | **Component** (`modules/<mod>/components/`) | Visual puro, sem side effects |

**Regra prática:** se o código acessa `this.$services`, `this.$router`, ou `this.$store`, ele pertence ao container. Se é puramente visual, pertence ao component. A page é o ponto de entrada — faz o mínimo necessário (layout + asyncData + delegação).

## Quando Usar Vuex vs Container State

| Cenário | Solução |
|---|---|
| Estado usado só dentro de um container e seus filhos | `data()` do container — **não usar Vuex** |
| Estado compartilhado entre containers na mesma página | Props via page ou provide/inject |
| Estado que persiste entre navegações (ex: filtros globais) | **Vuex store module** em `modules/<mod>/store/` |
| Estado que precisa ser acessado de qualquer lugar (ex: user info) | **Vuex** (já existe em `store/`) |

Na dúvida, começar com `data()` do container. Migrar para Vuex somente quando o estado precisar ser acessado fora do contexto do container.

## Service Registration

Services são registrados automaticamente em `services/index.js`. Para services de módulo:

1. Criar o arquivo em `modules/<módulo>/services/<nome>.js` (pattern factory: `(axiosInstance, ctx) => ({...})`)
2. Importar e registrar em `services/index.js`:
```js
import meuModuloService from '@/modules/meu-modulo/services/meuService'
// Na seção de registro:
services.meuService = meuModuloService(axiosInstance, ctx)
```
3. Acessar via `this.$services.meuService` em qualquer container ou page

## Convenções Gerais do Projeto

- **Vue 2 Options API** (não usar Composition API)
- **Nuxt 2 + @nuxt/bridge** — file-based routing, `asyncData`, `fetch`, layouts
- **Tailwind CSS** — estilização principal; classes utilitárias do DesignSystem para tokens de cor/tipografia
- **`this.$services`** — única forma de acessar a camada de API
- **`this.$vertical`** — vertical atual; `this.$isConcursos`, `this.$isMedicina` etc. para adaptar comportamento
- **Feature flags** via `this.$store.getters['features/<flag>']` ou componente `<beta-behavior>`
- **Vuex** para estado compartilhado entre componentes não relacionados (ver tabela acima)
- **`ctx.$log`** para log de erros em services (não `console.log`)
