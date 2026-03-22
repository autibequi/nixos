# Templates de Screen Types

## `list` — Listagem com busca, paginação e ações

**Componentes shared de referência:**
- `src/modules/shared/components/Lists/TableItems.vue` — tabela de itens
- `src/modules/shared/components/Lists/SortHeader.vue` — cabeçalho com ordenação
- `src/modules/shared/components/Lists/Pagination.vue` — paginação
- `src/modules/shared/components/search-bar.vue` — barra de busca
- `src/modules/shared/components/empty-state/index.vue` — estado vazio

**Estrutura padrão list:**

```vue
<template>
  <q-page class="q-px-xl q-pb-lg bg-grey-1 ui-overflow-auto">
    <page-header title="Título da Página" />
    <search-bar
      class="q-mt-lg"
      @search="query => searchQuery = query"
    />
    <table-items
      :items="items"
      :loading="loading"
      @edit="handleEdit"
      @delete="handleDelete"
    />
    <pagination
      :pagination-options="paginationOptions"
      @change="newPagination => paginationOptions = newPagination"
    />
    <!-- Modals e Drawers -->
  </q-page>
</template>

<script>
import services from '../../services'

export default {
  name: 'NomeDaPagina',
  data () {
    return {
      items: [],
      loading: false,
      searchQuery: '',
      paginationOptions: { currentPage: 1, currentPerPage: 20, total: 0 }
    }
  },
  watch: {
    searchQuery () { this.fetchItems() },
    'paginationOptions.currentPage' () { this.fetchItems() }
  },
  created () {
    this.fetchItems()
  },
  methods: {
    async fetchItems () {
      this.loading = true
      try {
        const res = await services.nomeDaEntidade.getItems(this.paginationOptions, { query: this.searchQuery })
        this.items = res.data.data
        this.paginationOptions.total = res.data.meta.total
      } finally {
        this.loading = false
      }
    }
  }
}
</script>
```

---

## `form` — Criação ou edição de entidade

**Componentes shared de referência:**
- `src/modules/shared/components/input-text/index.vue`
- `src/modules/shared/components/TextArea/index.vue`
- `src/modules/shared/components/toggle/index.vue`
- `src/modules/shared/components/input-date-time/index.vue`
- `src/modules/shared/components/Modals/BaseModal.vue` — wrapper de modal
- `QBtn` do Quasar para ações

**Validação:** use `vee-validate` v3 (já instalado). Wrap com `<ValidationObserver>` e use `<ValidationProvider>` por campo.

---

## `detail` — Visualização de entidade única

**Componentes shared de referência:**
- `src/modules/shared/components/tab-bar/index.vue` — tabs de seções
- `src/modules/shared/components/Tabs/index.vue`
- `src/modules/shared/components/Modals/BaseModal.vue`
- `src/modules/shared/components/delete-confirmation-modal.vue`
- `QCard`, `QCardSection` do Quasar

**Padrão:** buscar entidade por `:id` da rota no `created()`, renderizar seções, abrir modais/drawers para edição inline.

---

## `composite` — Combinação

Combine os padrões acima na mesma página. Exemplo: lista de itens no painel esquerdo + detalhe do item selecionado no direito. Use `QSplitter` do Quasar para layouts divididos.

---

## Padrões Cross-Screen

### CTable — Tabela com paginação e ordenação

O `CTable` (em `src/modules/shared/components/c-table/CTable.vue`) é o componente de tabela custom do BO. Aceita colunas configuráveis, paginação e ordenação:

```vue
<c-table
  :columns="columns"
  :data="items"
  :pagination="paginationOptions"
  :items-per-page="[10, 20, 50]"
  @change-pagination-current-page="page => { paginationOptions.currentPage = page; fetchItems() }"
  @change-pagination-per-page="pp => { paginationOptions.currentPerPage = pp; fetchItems() }"
  @change-order-by="order => { orderBy = order; fetchItems() }"
>
  <template #column-actions="{ item }">
    <q-btn flat icon="edit" @click="handleEdit(item)" />
    <q-btn flat icon="delete" @click="handleDelete(item)" />
  </template>
</c-table>
```

**Definição de colunas:**
```js
columns: [
  { label: 'Nome', attribute: 'name', isOrderable: true, flexWeight: 2 },
  { label: 'Status', attribute: 'status', isOrderable: true, flexWeight: 1 },
  { label: 'Ações', attribute: 'actions', flexWeight: 1, maxWidth: '120px' }
]
```

**Paginação padrão:**
```js
paginationOptions: { currentPage: 1, currentPerPage: 20, maxPage: 1 }
```

Alternativa: `QTable` do Quasar para tabelas mais simples sem paginação server-side.

### Dialogs e Modais

O BO tem dois plugins globais para interações modais:

**`this.$dialog` — Confirmação simples (Promise-based):**
```js
async handleDelete (item) {
  const confirmed = await this.$dialog.show({
    title: 'Confirmar exclusão',
    message: `Deseja excluir "${item.name}"?`,
    confirmButtonName: 'Excluir',
    cancelButtonName: 'Cancelar'
  })
  if (!confirmed) return
  await services.minhaEntidade.deleteItem(item.id)
  this.fetchItems()
}
```

**`this.$modal` — Modal com componente custom:**
```js
handleEdit (item) {
  this.$modal.show({
    component: EditItemModal,
    props: { item },
    closeOnOverlayClick: false,
    onClose: () => this.fetchItems()
  })
}
```

Nunca criar modais inline com `v-if` — usar `$dialog` para confirmações e `$modal` para formulários.

### Notificações (Toast)

```js
// Sucesso
this.$q.notify({ type: 'positive', message: 'Item criado com sucesso', position: 'top' })

// Erro
this.$q.notify({ type: 'negative', message: 'Erro ao criar item', position: 'top', multiLine: true })
```
