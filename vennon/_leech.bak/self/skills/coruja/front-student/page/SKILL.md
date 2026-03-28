---
name: front-student/page
description: Use when creating, modifying, or refactoring any Nuxt page in front-student — covers file-based routing, layout selection, middleware, asyncData vs mounted, container delegation pattern, and head/meta setup. Applies to new pages, modifying existing pages, changing data fetching, and updating layout or middleware.
---

# fs-page: Criar Página no front-student

## Localização e Roteamento

Pages ficam em `pages/` e seguem roteamento **file-based do Nuxt**:

| Arquivo | Rota gerada |
|---|---|
| `pages/cast/index.vue` | `/cast` |
| `pages/cast/album/_id.vue` | `/cast/album/:id` |
| `pages/todos-os-cursos/_slug/index.vue` | `/todos-os-cursos/:slug` |

**Não existe registro manual de rotas** — o Nuxt gera automaticamente.

## Layouts Disponíveis

Defina `layout` na opção do componente:

| Layout | Quando usar |
|---|---|
| `'navigation'` | Páginas autenticadas com menu lateral e navegação (padrão para a maioria das páginas) |
| `'default'` | Layout mínimo, sem menu (apenas `FeatureProvider`) |
| `'plg'` | Fluxo de PLG (product-led growth) |
| `'navigationDarkMode'` | Navegação com suporte a dark mode |
| `'navigationWithoutPadding'` | Navegação sem padding lateral |

## Middleware

Use middleware para proteção de rotas:

```js
middleware: [
  'authenticated',        // requer login
  'featureProtected',     // protege por feature flag
  'mobileProtected',      // bloqueia mobile se necessário
  'accessRoleProtected'   // protege por role de acesso
]
```

## Padrão de Página — Delegação para Container

Páginas são **delegadoras** — fazem fetch inicial via `asyncData` (SSR) e delegam renderização para containers ou componentes do módulo.

```vue
<template>
  <meu-modulo-container
    :initial-data="initialData"
    :vertical="$vertical"
  />
</template>

<script>
import MeuModuloContainer from '@/modules/meu-modulo/containers/MeuModulo'

export default {
  name: 'MeuModuloPage',

  components: {
    MeuModuloContainer
  },

  layout: 'navigation',

  middleware: [
    'authenticated',
    'featureProtected'
  ],

  async asyncData ({ $services, params, error }) {
    try {
      const data = await $services.meuService.getData(params.id)
      return { initialData: data }
    } catch (err) {
      error({ statusCode: 404, message: 'Não encontrado' })
    }
  },

  head () {
    return {
      title: 'Título da Página | Estratégia'
    }
  },

  meta: {
    pageName: 'nome da página para analytics'
  }
}
</script>
```

## Padrão de Página — Self-Contained

Para páginas simples que não justificam criar um container separado:

```vue
<template>
  <div class="flex flex-col">
    <div v-if="loading" class="flex justify-center p-8">
      <c-loading />
    </div>
    <template v-else>
      <h1 class="c-text-h1 p-8">{{ title }}</h1>
      <meu-componente
        v-for="item in items"
        :key="item.id"
        :item="item"
        @action="handleAction"
      />
    </template>
  </div>
</template>

<script>
import { CLoading } from '@estrategiahq/coruja-web-ui'
import MeuComponente from '@/modules/meu-modulo/components/MeuComponente'

export default {
  name: 'NomeDaPagina',

  components: {
    CLoading,
    MeuComponente
  },

  layout: 'navigation',

  middleware: ['authenticated'],

  async asyncData ({ $services }) {
    const result = await $services.meuService.getItems()
    return { items: result.data }
  },

  data: () => ({
    loading: false,
    title: 'Minha Página'
  }),

  async mounted () {
    // Para dados client-only que não precisam de SSR
  },

  methods: {
    handleAction (payload) {
      // lógica
    }
  },

  head () {
    return { title: 'Minha Página' }
  }
}
</script>
```

## asyncData vs mounted

| Critério | `asyncData` | `mounted` |
|---|---|---|
| Execução | Servidor + cliente (SSR) | Apenas cliente |
| Acesso a `this` | Não (recebe contexto Nuxt) | Sim |
| Quando usar | Dados críticos para SEO e render inicial | Dados client-only, reatividade pós-render |
| Parâmetros | `{ $services, params, query, error, redirect, $vertical }` | via `this.$services` |

## Feature Flags em Páginas

```vue
<template>
  <feature-provider>
    <beta-behavior ab-feature-name="nova_feature">
      <template #show>
        <novo-componente />
      </template>
      <template #hide>
        <componente-antigo />
      </template>
    </beta-behavior>
  </feature-provider>
</template>
```

## Acessar Params e Query

```js
// asyncData
async asyncData ({ $services, params, query }) {
  const id = params.id
  const page = query.page || 1
  return { data: await $services.myService.getItem(id) }
}

// mounted/methods
this.$route.params.id
this.$route.query.page
```

## Fluxo de Execução

1. Receber: nome da página, rota desejada, módulo alvo, dados necessários
2. Verificar se o módulo já tem container adequado ou se a página deve ser self-contained
3. Definir layout e middlewares necessários
4. Implementar `asyncData` para dados SSR e `mounted` para dados client-only
5. Criar `pages/<caminho>/index.vue` (ou `pages/<caminho>/_param.vue`)
