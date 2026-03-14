---
name: front-student/route
description: Use when creating, modifying, or refactoring any route in front-student — covers Nuxt file-based routing conventions, dynamic params, nested routes, and route-level configuration (layout, middleware, meta). Applies to new routes, modifying existing routes, changing params or middleware, and restructuring nested routes.
---

# fs-route: Criar Rota no front-student

## Contexto do Projeto

Rotas são **file-based** — o Nuxt gera automaticamente a partir da estrutura de `pages/`. **Não existe arquivo de registro manual de rotas.**

## Convenção de Arquivos → Rotas

| Arquivo em `pages/` | Rota gerada |
|---|---|
| `pages/cast/index.vue` | `/cast` |
| `pages/cast/favorites.vue` | `/cast/favorites` |
| `pages/cast/album/_id.vue` | `/cast/album/:id` |
| `pages/todos-os-cursos/_slug/index.vue` | `/todos-os-cursos/:slug` |
| `pages/todos-os-cursos/_slug/_type/index.vue` | `/todos-os-cursos/:slug/:type` |
| `pages/resultado-pesquisa/_.vue` | `/resultado-pesquisa/*` (wildcard) |

### Regras de nomeação

- **Diretório com `index.vue`** → rota exata do diretório (`/cast`)
- **Arquivo com `_param`** → parâmetro dinâmico (`:param`)
- **Arquivo `_.vue`** → catch-all/wildcard
- Use **kebab-case** para nomes de diretórios e arquivos (`todos-os-cursos`, não `todosCursos`)

## Configuração de Rota no Componente de Página

Toda página deve declarar:

```vue
<script>
export default {
  // Layout a ser usado (obrigatório se não for o default)
  layout: 'navigation',

  // Middleware de proteção (na ordem de execução)
  middleware: [
    'authenticated',       // requer usuário logado
    'featureProtected',    // protege por feature flag
    'mobileProtected',     // bloqueia em mobile se necessário
    'accessRoleProtected'  // protege por role
  ],

  // Metadados para analytics
  meta: {
    pageName: 'nome da página'
  },

  head () {
    return {
      title: 'Título da Página | Estratégia'
    }
  }
}
</script>
```

## Acessar Params e Query na Página

```js
// asyncData (SSR) — via contexto Nuxt
async asyncData ({ params, query }) {
  const id = params.id          // de _id.vue
  const slug = params.slug      // de _slug.vue
  const page = query.page || 1  // ?page=2
}

// Em métodos/computed — via $route
this.$route.params.id
this.$route.params.slug
this.$route.query.page
```

## Navegação Programática

```js
// Navegar para rota
this.$router.push('/cast/album/123')
this.$router.push({ path: `/cast/album/${id}` })

// Com query params
this.$router.push({ path: '/resultado-pesquisa', query: { q: 'texto' } })

// Substituir histórico (sem voltar)
this.$router.replace('/cast')
```

## Links no Template

```vue
<!-- NuxtLink (preferencial, carrega lazy) -->
<nuxt-link to="/cast">Cast</nuxt-link>
<nuxt-link :to="`/cast/album/${album.id}`">Ver álbum</nuxt-link>

<!-- RouterLink (equivalente) -->
<router-link to="/cast">Cast</router-link>
```

## Middlewares Disponíveis

Ficam em `middleware/`. Principais:

| Middleware | Proteção |
|---|---|
| `authenticated` | Redireciona para login se não autenticado |
| `featureProtected` | Bloqueia se feature flag desabilitada para a rota |
| `mobileProtected` | Redireciona mobile para tela específica |
| `accessRoleProtected` | Bloqueia por role de acesso do usuário |
| `manutencao` | Global — redireciona se em manutenção |

## Rotas Aninhadas (Nested Routes)

Para layouts com `<nuxt-child>`, criar um arquivo `.vue` com o mesmo nome do diretório:

```
pages/
  objetivos/
    index.vue        → /objetivos
    _id/
      index.vue      → /objetivos/:id
      conteudo.vue   → /objetivos/:id/conteudo
```

## Fluxo de Execução

1. Definir a rota desejada (ex: `/meu-modulo/:slug`)
2. Criar a estrutura de diretório/arquivo correspondente em `pages/`
3. Definir `layout`, `middleware` e `head` na opção do componente
4. Implementar `asyncData` para dados SSR se necessário
5. Invocar `front-student/page` para o conteúdo da página
