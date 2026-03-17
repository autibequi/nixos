---
name: bo-container/component
description: Use when creating, modifying, or refactoring any UI component in bo-container — covers priority lookup (shared → Quasar → CorujaUI → custom), placement, and Vue 2 component structure. Applies to new components, modifying existing ones, moving/splitting components, and changing props or logic.
---

# bo-component: Criar Componente no bo-container

## Prioridade de Resolução (SEMPRE nesta ordem)

1. **`src/modules/shared/components/`** — verifique se existe algo que atenda (mesmo que precise de uma prop a mais)
2. **Quasar 1.x** — componentes registrados em `quasar.conf.js`: `QTable`, `QDialog`, `QDrawer`, `QInput`, `QSelect`, `QBtn`, `QCard`, `QExpansionItem`, etc.
3. **`@estrategiahq/coruja-web-ui`** — design system interno (CorujaUI)
4. **Criar componente novo** — apenas se nenhuma opção acima atender

**Não adapte aparência** de componentes existentes via CSS custom — use props e slots.

## Onde Criar

- **Reutilizável entre módulos** → `src/modules/shared/components/<nome>/index.vue`
- **Específico do módulo** → `src/modules/<módulo>/components/<Categoria>/<Nome>/index.vue`

Categorias comuns em módulos: `Modals/`, `Drawers/`, `Lists/`, `Cards/`, `Forms/`

## Estrutura Vue 2 Padrão

```vue
<template>
  <div class="nome-do-componente">
    <!-- conteúdo -->
  </div>
</template>

<script>
export default {
  name: 'NomeDoComponente',

  props: {
    value: {
      type: String,
      default: ''
    },
    isOpen: {
      type: Boolean,
      default: false
    }
  },

  data () {
    return {
      localState: null
    }
  },

  computed: {
    computedValue () {
      return this.value
    }
  },

  methods: {
    handleAction () {
      this.$emit('action', this.localState)
    }
  }
}
</script>
```

## Horizontais (Verticais)

As cores por horizontal (`concursos`, `medicina`, `militares`, `oab`, `vestibulares`, `carreiras-juridicas`) são aplicadas automaticamente pelos componentes CorujaUI e Quasar via tokens CSS. Não hardcode cores — use as classes utilitárias do Quasar (`text-primary`, `bg-brand-*`) ou variáveis SCSS de `src/css/quasar.variables.scss`.

## Componentes Globais

Componentes em `src/modules/core/components/` são auto-registrados globalmente por `src/boot/components.js`. Disponíveis sem import: `page-header`, e outros presentes nesse diretório.

## Fluxo de Execução

1. Receber descrição do componente necessário
2. Buscar em `src/modules/shared/components/` (ler a lista de arquivos)
3. Verificar se algum componente Quasar registrado em `quasar.conf.js` atende
4. Verificar CorujaUI
5. Se nenhum atender: decidir se vai para `shared/` ou para o módulo
6. Criar o componente
