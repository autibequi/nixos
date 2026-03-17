---
name: front-student/component
description: Use when creating, modifying, or refactoring any UI component in front-student — covers priority lookup (DesignSystem → share → custom), placement decisions, container vs component pattern, and Vue 2 component structure. Applies to new components, modifying existing ones, moving/splitting components, and changing props or logic.
---

# fs-component: Criar Componente no front-student

## Prioridade de Resolução (SEMPRE nesta ordem)

1. **`@estrategiahq/coruja-web-ui`** — Design System interno. Componentes com prefixo `C` (ex: `CIcon`, `CSearchBar`, `CDropdownSmall`, `CCard`, `CButton`, `CModal`, `CToast`, `CCastCard`, `COptions`). Verificar a lib antes de criar qualquer componente.
2. **`modules/share/components/`** — componentes reutilizáveis entre módulos. Verificar subdiretórios: `Cards/`, `AccessRole/`, `Feature/`, `Header/`, `ListItems/`, `Charts/`, etc.
3. **`components/`** — componentes globais da aplicação (modais globais, overlays, menus).
4. **Criar componente novo** — apenas se nenhuma opção acima atender.

**Não adapte aparência** de componentes existentes via CSS custom — use props e slots.

## Padrão: Componente vs Container

| Tipo | Localização | Responsabilidade |
|---|---|---|
| **Component** | `modules/<módulo>/components/` ou `modules/share/components/` | Puramente apresentacional, recebe dados via props |
| **Container** | `modules/<módulo>/containers/` | Smart — faz fetch de dados, coordena estado, passa para componentes |

Use **containers** quando precisar de lógica de dados (chamadas a `this.$services`, Vuex). Use **components** para renderização pura.

## Onde Criar Componente Novo

- **Reutilizável entre módulos** → `modules/share/components/<Nome>/index.vue`
- **Específico do módulo** → `modules/<módulo>/components/<Nome>.vue`
- **Container de módulo** → `modules/<módulo>/containers/<Nome>.vue`

## Estrutura Vue 2 Options API — Componente Presentacional

```vue
<template>
  <div class="nome-do-componente">
    <!-- Use classes Tailwind + classes do DesignSystem (c-text-*, c-border-*, etc.) -->
    <slot />
  </div>
</template>

<script>
import { CIcon } from '@estrategiahq/coruja-web-ui'

export default {
  name: 'NomeDoComponente',

  components: {
    CIcon
  },

  props: {
    title: {
      type: String,
      required: true
    },
    isLoading: {
      type: Boolean,
      default: false
    }
  },

  emits: ['action'],

  methods: {
    handleAction () {
      this.$emit('action', this.title)
    }
  }
}
</script>
```

### Anti-pattern: Lógica de Negócio em Componente Presentacional

```vue
<!-- ERRADO: componente navegando e fazendo lógica de negócio -->
<script>
export default {
  methods: {
    handleClick () {
      this.$router.push(`/simulados/${this.item.id}`)  // navegação é lógica de negócio
    },
    async deleteItem () {
      await this.$services.myService.delete(this.item.id)  // chamada a service é lógica
    }
  }
}
</script>

<!-- CERTO: componente emite eventos, quem decide o que fazer é o container/page -->
<script>
export default {
  emits: ['select', 'delete'],
  methods: {
    handleClick () {
      this.$emit('select', this.item)  // emite dado, não decide ação
    },
    handleDelete () {
      this.$emit('delete', this.item.id)  // emite intenção, não executa
    }
  }
}
</script>
```

Componentes presentacionais **nunca** acessam `this.$router`, `this.$services` ou `this.$store`. Eles recebem dados via props e comunicam intenções via `$emit`. O container ou page é quem decide o que fazer com essas intenções.
```

## Plugins Globais Disponíveis em Containers

Containers (smart components) têm acesso a vários plugins injetados globalmente:

| Plugin | Acesso | Uso |
|---|---|---|
| `this.$services` | API calls | `this.$services.myService.getItems()` |
| `this.$store` | Vuex state | `this.$store.dispatch('module/action')`, `this.$store.commit('module/MUTATION')` |
| `this.$g` | Drawers/overlays globais | `this.$g.drawer.right.show()`, `this.$g.overlay.show()` |
| `this.$bus` | Event bus | `this.$bus.$emit('event')`, `this.$bus.$on('event', handler)` |
| `this.$vertical` | Vertical atual (string) | `'concursos'`, `'medicina'`, etc. |
| `this.$isConcursos` | Boolean helpers | `this.$isMedicina`, `this.$isMilitares`, etc. |
| `this.$log` | Logger | `this.$log('contexto', error)` |
| `this.$router` | Vue Router | `this.$router.push(...)` |
| `this.$route` | Rota atual | `this.$route.params.id` |

Componentes **presentacionais** não devem usar nenhum desses diretamente (exceto `$vertical` para estilização condicional). Containers são o lugar certo.

## Estrutura Vue 2 — Container (Smart Component)

```vue
<template>
  <nome-componente
    :items="items"
    :loading="loading"
    @action="handleAction"
  />
</template>

<script>
import NomeComponente from '../components/NomeComponente'

export default {
  name: 'NomeContainer',

  components: { NomeComponente },

  data () {
    return {
      items: [],
      loading: false
    }
  },

  async mounted () {
    await this.fetchItems()
  },

  methods: {
    async fetchItems () {
      this.loading = true
      try {
        const result = await this.$services.myService.getItems()
        this.items = result.data
      } finally {
        this.loading = false
      }
    },
    handleAction (payload) {
      // lógica de ação
    }
  }
}
</script>
```

## Classes de Estilo

- **Tailwind** é a principal ferramenta de estilo (`flex`, `p-4`, `text-xl`, etc.)
- **Design System tokens** via classes CSS do Coruja: `c-text-primary-200`, `c-text-gray-300`, `c-border-gray-300`, `c-text-b2`, `c-text-label`
- **Não hardcode cores** — use tokens do DesignSystem ou classes Tailwind

### Anti-patterns de Estilo

```vue
<!-- ERRADO: CSS custom para coisas que Tailwind resolve -->
<style scoped>
.card { display: flex; padding: 16px; margin-bottom: 12px; }
.card-title { font-size: 18px; font-weight: 600; color: #333; }
</style>

<!-- CERTO: Tailwind + tokens do DesignSystem -->
<template>
  <div class="flex p-4 mb-3">
    <span class="text-lg font-semibold c-text-gray-300">{{ title }}</span>
  </div>
</template>
<!-- Sem <style> — Tailwind e tokens cobrem tudo -->
```

O front-student usa Tailwind extensivamente. CSS custom em `<style scoped>` só faz sentido para animações, pseudo-elements complexos, ou layout que Tailwind genuinamente não cobre. Na dúvida, é Tailwind.

## Vertical

O vertical atual está disponível via `this.$vertical` e `this.$isConcursos`, `this.$isMedicina`, etc. Use para adaptar comportamento sem duplicar componentes.

## Fluxo de Execução

1. Receber descrição do componente necessário
2. Buscar em `@estrategiahq/coruja-web-ui` (prefixo `C`)
3. Buscar em `modules/share/components/`
4. Buscar em `components/`
5. Decidir: é container (tem lógica de dados) ou component (puramente visual)?
6. Decidir: específico do módulo ou compartilhável?
7. Criar o componente na localização correta
