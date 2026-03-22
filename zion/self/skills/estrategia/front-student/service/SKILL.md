---
name: front-student/service
description: Use when creating, modifying, or refactoring any API service in a front-student module — covers factory function pattern, axios instance selection, service registration, and error handling. Applies to new services, adding/changing methods, refactoring service calls, and updating endpoints or payload shapes.
---

# fs-service: Criar ou Extender Service no front-student

## Contexto do Projeto

Services ficam em dois lugares:

- **Globais** → `services/<nome>.js` (ex: `services/accounts.js`, `services/rankings.js`)
- **Por módulo** → `modules/<módulo>/services/<nome>.js` (ex: `modules/cast/services/cast.js`)

Todos os services são registrados manualmente em `services/index.js` e injetados como `this.$services` via `plugins/services.js`.

**Nunca** configure axios diretamente nos services — o axios já vem configurado com auth headers, retry, e vertical.

## Padrão de Factory Function

Services são **factory functions** que recebem `(axiosInstance, ctx)` e retornam um objeto.

> **Antes de criar**: leia `services/index.js` para verificar se o service já existe ou se já há métodos similares em outro service do módulo.

### Padrão recomendado para código novo

Baseado em `services/studentExams.js` — inclui logging estruturado e repasse de params no erro:

```js
export default (axiosInstance, ctx) => ({
  async getItems ({ page = 1, perPage = 20 } = {}) {
    try {
      const { data } = await axiosInstance.get('/v3/items', {
        params: { page, per_page: perPage }
      })
      return data
    } catch (error) {
      error.params = { page, perPage }
      ctx.$log('Service <items.getItems> falhou', error)
      throw error
    }
  },

  async getItem (id) {
    try {
      const { data } = await axiosInstance.get(`/v3/items/${id}`)
      return data
    } catch (error) {
      error.params = { id }
      ctx.$log('Service <items.getItem> falhou', error)
      throw error
    }
  },

  async createItem (payload) {
    try {
      const { data } = await axiosInstance.post('/v3/items', payload)
      return data
    } catch (error) {
      error.params = { payload }
      ctx.$log('Service <items.createItem> falhou', error)
      throw error
    }
  }
})
```

**Detalhes do padrão:**
- `error.params = { ... }` — adicione os parâmetros relevantes ao objeto de erro antes de logar (facilita debugging)
- `ctx.$log(mensagem, error)` — injetado via `plugins/log.js`; use para observabilidade
- `throw error` — sempre relancar para que o caller trate o erro
- O parâmetro pode ser chamado `axiosInstance` ou `HTTPClient` (ambos aparecem no codebase)

### Quando omitir `ctx`

Se o service for simples e não precisar de logging (ex: wrappers finos sobre helpers), `ctx` pode ser omitido:

```js
export default (axiosInstance) => ({
  async getItem (id) {
    const { data } = await axiosInstance.get(`/v3/items/${id}`)
    return data
  }
})
```

Nesse caso, o error handling pode ser feito pelo caller ou pelo wrapper global (veja abaixo).

### Padrões existentes no codebase (não copiar para código novo)

O codebase tem variações históricas — ao **estender** um service existente, siga o padrão já adotado nele:

| Padrão | Onde aparece | Observação |
|---|---|---|
| `(axiosInstance, ctx)` + try/catch + `ctx.$log` | `services/studentExams.js`, maioria dos services globais | **Preferido para código novo** |
| `axiosInstance =>` + helper `doRequest` sem ctx | `modules/cast/services/cast.js` | Padrão legado do módulo cast |
| Sem try/catch (wrapper global via `addTryCatchOnEachServiceAction`) | `services/notebooks.js` | Aplicado na hora do registro em `index.js` |

## Instâncias Axios Disponíveis

Leia `plugins/services.js` e `services/index.js` para entender as instâncias:

| Parâmetro | baseURL | Uso |
|---|---|---|
| `axiosInstance` | `bffUrl` (BFF principal) | maioria das chamadas |
| `ecommerceAxiosInstance` | URL do e-commerce | pagamentos, produtos |
| `ldiAxiosInstance` | `bffUrl` + header `X-LDI-Type` | rotas de trilhas estratégicas |

Se o service usar apenas o BFF principal, declare só `axiosInstance`.

## Registrar no services/index.js

Após criar o service, registrá-lo em `services/index.js`:

```js
// 1. Importar
import myNewService from '@/modules/meu-modulo/services/myNew'

// 2. Adicionar no objeto de retorno da factory
export default (axiosInstance, ecommerceAxiosInstance, ldiAxiosInstance, ctx) => {
  return {
    // ... outros services
    myNew: myNewService(axiosInstance, ctx),
  }
}
```

## Usar nos Componentes/Páginas

```js
// Em páginas com asyncData (SSR)
async asyncData ({ $services }) {
  const data = await $services.myNew.getItems()
  return { data }
}

// Em componentes/métodos
async fetchData () {
  const result = await this.$services.myNew.getItems({ page: 1, perPage: 20 })
  this.items = result.data
}
```

## Decisão: Global vs Módulo

- **Global** (`services/`) → entidade usada em múltiplos módulos (ex: `accounts`, `search`, `features`)
- **Por módulo** (`modules/<módulo>/services/`) → entidade específica do módulo (ex: `cast.js` só para Cast)

## Fluxo de Execução

1. Ler `services/index.js` para ver services existentes e verificar se a entidade já existe
2. Definir onde criar: global ou por módulo
3. Se estiver **estendendo** service existente: identificar e seguir o padrão de error handling já adotado nele
4. Se estiver **criando** service novo: usar o padrão recomendado com `(axiosInstance, ctx)` + try/catch + `ctx.$log`
5. Registrar em `services/index.js`
