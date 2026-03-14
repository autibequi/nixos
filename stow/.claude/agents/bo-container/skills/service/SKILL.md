---
name: bo-container/service
description: Use when creating, modifying, or refactoring any API service in a bo-container module — covers axios instance selection, class structure, method patterns, and loading behavior. Applies to new services, adding/changing methods, refactoring service calls, and updating endpoints or payload shapes.
---

# bo-service: Criar ou Extender Service no bo-container

## Contexto do Projeto

Services ficam em `src/modules/<módulo>/services/`. Cada módulo tem um `index.js` que:
1. Define instâncias axios para cada API (com e sem loading global)
2. Auto-importa todos os outros `.js` do diretório e instancia as classes passando `deps`
3. Exporta o objeto `services` com todas as instâncias

**Nunca** configure headers ou interceptors diretamente na classe — eles já estão no `index.js`.

## Padrão de Classe

```js
export default class {
  constructor (deps) {
    this.$http = deps.axiosFoo()           // com loading global (padrão)
    this.$httpNoLoad = deps.axiosFoo(false) // sem loading global
  }

  async getItems ({ page, perPage }, filters = {}) {
    return this.$http.get('/items', {
      params: { page, per_page: perPage, ...filters }
    })
  }

  async createItem (payload) {
    return this.$http.post('/items', payload)
  }

  async updateItem (id, payload) {
    return this.$http.put(`/items/${id}`, payload)
  }

  async deleteItem (id) {
    return this.$http.delete(`/items/${id}`)
  }
}
```

## Instâncias Axios Disponíveis (por módulo)

Leia o `services/index.js` do módulo para ver quais `deps` estão disponíveis. Cada instância tem uma **baseURL fixa** — o path relativo no service é concatenado a ela.

### Mapeamento de instâncias

| dep | baseURL | Usar quando o endpoint é... |
|---|---|---|
| `deps.axiosBO()` | `API_BO_URL` | `/bo/*` genérico (ex: `/bo/ldi/rankings`, `/bo/search`) |
| `deps.axiosCursos()` | `API_BO_URL/cursos` | `/bo/cursos/*` (ex: `/bo/cursos/books`) |
| `deps.axiosMyDocs()` | `API_BO_URL/materiais` | `/bo/materiais/*` |
| `deps.axiosBff()` | `API_BO_URL` + header `X-LDI-Type` | `/ldi/*` ou `/trilhas/*` (módulo ldi) |
| `deps.axiosCatalogs` | `API_CATALOGS_URL` | APIs de catálogo externas |
| `deps.axiosEcommerce()` | `API_ECOMMERCE_URL` | APIs de e-commerce |
| `deps.axiosCast()` | `API_CAST_URL` | APIs de cast/vídeo |
| `deps.axiosQuestions()` | `API_QUESTIONS_URL` | APIs de questões |

### Como escolher a instância correta

A instância certa depende do **path completo do endpoint no backend**:

1. **Identifique o path completo** do endpoint (ex: `/bo/ldi/rankings`)
2. **Verifique a baseURL** de cada instância disponível no `index.js` do módulo
3. **Escolha a que encaixa** — o path relativo no service é `path_completo - baseURL`

**Exemplo prático:** endpoint `/bo/ldi/rankings`
- `axiosCursos` tem baseURL `API_BO_URL/cursos` → path seria `/ldi/rankings` mas **não faz sentido** porque `/cursos/ldi/rankings` ≠ `/bo/ldi/rankings`
- `axiosBO` tem baseURL `API_BO_URL` → path relativo = `/ldi/rankings` ✅

**Regra rápida:** se o endpoint NÃO começa com `/bo/cursos/`, `/bo/materiais/`, ou outro prefixo específico, use `axiosBO`.

Se o módulo usa uma API diferente, adicione a instância no `index.js` do módulo seguindo o padrão existente.

## Decisão: Novo Arquivo vs Extender Existente

- **Novo arquivo:** entidade nova sem relação com services existentes. Nome = domínio da entidade (`ranking.js`, `result.js`).
- **Extender existente:** adicionar métodos relacionados a uma entidade que já tem service.

## Headers e Interceptors (já configurados no index.js)

O `index.js` de cada módulo já configura interceptors que injetam automaticamente:

- **`Authorization`** — token do `localStorage` (cookie de sessão)
- **`X-Vertical`** — vertical extraído da URL via `extractVerticalFromURL()`
- **`X-Requester-ID`** — ID do usuário logado

O interceptor de response trata automaticamente:
- **401** → limpa localStorage, redireciona para login
- **Erros de rede** → publica evento de loading error via event bus

Por isso, **nunca** configure headers ou interceptors na classe do service — eles já estão no `index.js`. O service só precisa fazer as chamadas HTTP.

## Error Handling nos Services

Para mostrar erros ao usuário, importe `getErrorMessage` do core:

```js
import { getErrorMessage } from '@/modules/core/apiErrors'

// No componente/page que chama o service:
try {
  await services.minhaEntidade.createItem(payload)
  this.$q.notify({ type: 'positive', message: 'Item criado' })
} catch (e) {
  this.$q.notify({ type: 'negative', message: getErrorMessage(e) })
}
```

`getErrorMessage` mapeia tags de erro do backend (ex: `"VALIDATION_ERROR"`) para mensagens legíveis em português.

## Fluxo de Execução

1. Ler `src/modules/<módulo>/services/index.js` para identificar deps disponíveis
2. Ler services existentes para verificar se a entidade já tem service
3. Criar ou modificar o arquivo de service
4. O `index.js` auto-importa — não é necessário registrar manualmente
