---
name: bo-container/route
description: Use when creating, modifying, or refactoring any route in a bo-container module — covers named views pattern, lazy imports, path conventions, and the ServiceLayout slot. Applies to new routes, modifying existing routes, changing route paths or guards, and updating lazy import targets.
---

# bo-route: Registrar Rota no bo-container

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

## Contexto do Projeto

Cada módulo tem seu próprio `src/modules/<módulo>/router/index.js` que exporta um array de rotas. Este array é importado em `src/router/routes.js` e injetado dentro da rota `/:vertical/` — **não modifique** o `routes.js` global.

## Padrão de Rota

```js
{
  path: 'ranking/results/:id',
  name: 'ranking-results',
  components: {
    default: () => import('../pages/Results'),
    ServiceLayout: () => import('../layouts/BaseLayout')  // use o layout do módulo
  }
}
```

### Named Views

- `default` → o conteúdo principal da página
- `ServiceLayout` → layout do módulo (sidebar, header específico). Verifique se o módulo tem `layouts/BaseLayout.vue`; se não tiver, omita o ServiceLayout.

### Convenção de paths

- Sempre relativos ao módulo: `ranking/results` (não `/ranking/results`)
- Params: `:id`, `:slug`
- Sub-recursos: `ranking/results/:id/details`

### Convenção de names

- Kebab-case: `ranking-results`, `ranking-results-detail`
- Único na aplicação inteira — prefixe com o módulo para evitar conflito

## Proteção de Rota por Permissão

Para rotas que precisam de permissão específica, use `routeRequiresPermission()`:

```js
import { routeRequiresPermission } from '@/modules/core/utils/permissions'

export default [
  {
    path: 'ranking/results',
    name: 'ranking-results',
    components: {
      default: () => import('../pages/Results'),
      ServiceLayout: () => import('../layouts/BaseLayout')
    },
    beforeEnter: routeRequiresPermission('ranking.results.read')
  }
]
```

Para múltiplas permissões, use um guard custom:

```js
beforeEnter: (to, from, next) => {
  const user = require('@/modules/core/utils/loggedUser').default
  if (user.hasPermission('modulo.recurso.read')) {
    next()
  } else {
    next({ name: 'forbidden' })
  }
}
```

## Fluxo de Execução

1. Ler `src/modules/<módulo>/router/index.js`
2. Verificar se já existe rota com path/name similar
3. Decidir se a rota precisa de `beforeEnter` com permissão
4. Adicionar a nova entrada no array
5. Verificar se o módulo tem layout próprio em `layouts/`
