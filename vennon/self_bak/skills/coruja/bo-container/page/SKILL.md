---
name: bo-container/page
description: Use when creating, modifying, or refactoring any Vue page in a bo-container module — covers screen type selection (list, form, detail, composite), shared component wiring, service integration, and permissions. Applies to new pages, modifying existing pages, changing data sources, and updating page structure or permissions.
---

# bo-page: Criar Página no bo-container

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

## Templates

Antes de executar, ler o arquivo de templates correspondente:

| Arquivo | Conteúdo |
|---|---|
| `templates/screen-types.md` | Templates Vue e componentes shared para cada screen type (list, form, detail, composite) |

## Localização

Páginas ficam em `src/modules/<módulo>/pages/<NomeDaPagina>/index.vue`

## Tipos de Screen

Quatro tipos disponíveis: `list` (listagem com busca/paginação), `form` (criação/edição), `detail` (visualização de entidade) e `composite` (combinação de padrões).

-> Ver templates de cada screen type em `templates/screen-types.md`

## Wrapper de Página

Sempre use `<q-page class="q-px-xl q-pb-lg bg-grey-1 ui-overflow-auto">` como elemento raiz.

## page-header (Global)

Componente `page-header` está auto-registrado globalmente. Use-o para o título:

```vue
<page-header title="Nome da Seção" />
```

## Permissões

Proteja ações sensíveis com `$loggedUser.hasPermission('modulo.acao')`:

```vue
<q-btn
  v-if="$loggedUser.hasPermission('cursos.edit')"
  @click="handleEdit"
>
  Editar
</q-btn>
```

## Importando Services

```js
import services from '../../services'
// uso: services.nomeDaEntidade.getItems(...)
```

## Fluxo de Execução

1. Receber: módulo, nome da página, tipo de screen, service alvo, campos/colunas
2. Ler o service correspondente para conhecer os métodos disponíveis
3. Resolver componentes shared para o tipo de screen (bo-container/component se necessário)
4. Criar `src/modules/<módulo>/pages/<NomeDaPagina>/index.vue`
