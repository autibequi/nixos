---
name: front-student/inspector
description: Inspeção de qualidade e contrato no front-student. Use para validar features novas, mudanças em services, alinhamento de contrato com o BFF/backend, response shape changes, e padrões Nuxt 2. Abrange: services, composables, containers, pages, e adaptadores de response.
---

# fs-inspector: Inspeção do Front Student

## Quando usar

- Após mudança em services que chamam endpoints do BFF ou monolito
- Quando o backend muda a shape de um response (novo campo, renomeação, nested vs flat)
- Para verificar se composables/containers consomem o response corretamente
- Para validar que adaptadores/mappers estão atualizados

## Estrutura do Projeto

```
modules/<módulo>/
  services/        ← factory functions (axiosInstance, ctx) => {}
  composables/     ← lógica stateful (Vue 3 style dentro de Nuxt 2)
  containers/      ← smart components, acessam services/store
  components/      ← presentational
  pages/           ← entry points (asyncData, layout, middleware)
  types/           ← JSDoc types (Chapter.js, Item.js, etc.)

services/          ← services globais (usados em múltiplos módulos)
```

**Instâncias axios disponíveis:**

| Parâmetro | baseURL | Uso |
|-----------|---------|-----|
| `axiosInstance` | `bffUrl` | BFF principal (maioria) |
| `ldiAxiosInstance` | `bffUrl` + `X-LDI-Type` | rotas LDI/trilhas |
| `ecommerceAxiosInstance` | e-commerce URL | pagamentos |

## Checklist de Inspeção

### Services (`modules/<módulo>/services/*.js` ou `services/*.js`)

- [ ] Factory function `(axiosInstance, ctx) => ({})` — sem estado
- [ ] try/catch + `error.params = {...}` + `ctx.$log(msg, error)` + `throw error`
- [ ] Sem headers ou configuração axios (já no plugin)
- [ ] Sem lógica de negócio — apenas chamadas HTTP
- [ ] Registrado em `services/index.js`

#### Armadilhas de Contrato com o BFF/Backend

- **Response shape change**: Se o backend mudou de `data.chapters[]` para `data.toc_data.toc[]`, **todos os consumidores** (composables, containers, pages) precisam ser atualizados. Verificar campo a campo.
- **Campo renomeado**: `chapter_id` → `id` quebra silenciosamente — JS retorna `undefined` sem erro.
- **Nested vs flat**: BFF pode passar de retornar lista flat para objeto com sub-objetos. Composables que desestruturavam `const { chapters } = data` vão receber `undefined`.
- **`toc_id` vs `content_id` vs `chapter_id`**: Com features de cache de TOC, IDs podem vir em campos diferentes. Verificar qual campo o composable usa para navegação.

### Composables (`modules/<módulo>/composables/*.js`)

- [ ] Não acessam diretamente `$services` — recebem dados via props ou parâmetros
- [ ] Verificar todas as referências a campos do response: `data.chapters`, `data.toc_data`, `chapter.chapter_id`, `item.item_id`
- [ ] Se houver adaptador/mapper, verificar se foi atualizado junto com mudança de shape
- [ ] **`ContentAccessWatcher` pattern**: se o composable faz lookup por ID, verificar se aceita todos os campos de ID possíveis (`toc_id`, `content_id`, `chapter_id`)

### Containers e Pages

- [ ] Props passadas de container para presentational batem com o novo shape
- [ ] `:chapters="course?.chapters"` — se `chapters` foi movido para `toc_data.toc`, será `undefined`
- [ ] `asyncData` busca os dados corretos e os mapeia antes de retornar
- [ ] Sem acesso direto ao `$store` em components presentational

### Types (`modules/<módulo>/types/*.js`)

- [ ] JSDoc atualizado para refletir novos campos (`@property`)
- [ ] Se o type define `chapter_id` e o backend passou a retornar `toc_id`, o type está desatualizado

## Processo de Inspeção

### 1. Identificar o endpoint afetado e o que mudou no backend

```bash
# Ver o diff do backend para entender a nova shape
cd /workspace/home/estrategia/monolito
git diff main...HEAD -- apps/bff/internal/handlers/ | grep -A 20 "type.*Response\|type.*DTO"
```

### 2. Rastrear o caminho do dado no front-student

```
service → composable → container → page/component
         getCourse()   Course.js    LdiCourse.vue
```

Para cada etapa, verificar qual campo é acessado.

### 3. Verificar adaptadores/mappers

Buscar se existe camada de adaptação que isolaria o componente do shape do response:

```bash
grep -r "adapter\|mapper\|transform\|normalize" modules/<módulo>/
```

Se existir, verificar se foi atualizado. Se não existir e houver breaking change, recomendar criar um.

### 4. Verificar branch paralela

Se o backend já está em code review mas o front ainda usa shape antiga, pode haver uma branch separada no front-student. Verificar:

```bash
git branch -a | grep <ticket-id>
```

**Hipótese de branch incompleta**: se parte do código já usa o novo formato (ex: `ContentAccessWatcher` aceita `toc_id`) mas outra parte ainda usa o antigo (`Course.js` lê `chapters`), é sinal de que a adaptação foi iniciada mas não concluída.

## Formato de Output

```markdown
## front-student — [Feature/Branch]

### Services
- ✅ `getCourseChapters` — URL e parâmetros corretos
- ❓ `getCourse` — endpoint não foi modificado no backend nesta feature

### Composables / Containers
- 🔴 QUEBRADO: `Course.js:92` — lê `course.value.chapters`, backend retorna `toc_data.toc`
- 🔴 QUEBRADO: `LdiCourse.vue:31` — `:chapters="course?.chapters"` será undefined
- ✅ `ContentAccessWatcher.js` — já preparado para `toc_data.toc`

### Hipótese
- ⚠️ Branch paralela incompleta: adaptação iniciada mas não finalizada
  - Não fazer deploy do backend sem alinhar com o front-student

### Ações necessárias
1. Criar adapter em `Course.js` que normalize `toc_data.toc` para o formato esperado
2. OU atualizar `ContentLoader.js` para consumir `toc_data.toc` diretamente
```

## Aprendizados (desta inspeção)

### Response shape change é o risco mais crítico no front-student
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** BFF mudou de retornar `chapters[]` flat para `{ toc_data: { toc: [] } }`. `Course.js:92` ainda lia `course.value.chapters` → `undefined`. Quebra silenciosa — sem erro de compilação, sem erro de runtime visível, só funcionalidade sumindo.
**O que checar:** Ao inspecionar, buscar TODOS os acessos ao campo que mudou no response. `grep -r "\.chapters" modules/` para encontrar todos os callers.

### Adapatador parcialmente atualizado é sinal de branch incompleta
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** `ContentAccessWatcher.js` já usava `toc_data.toc` e aceitava `toc_id`/`content_id`, mas `Course.js` e `LdiCourse.vue` ainda usavam o formato antigo. Isso indica trabalho iniciado mas não finalizado.
**O que checar:** Se encontrar inconsistência de formato entre arquivos do mesmo módulo, investigar se há branch separada antes de concluir que é um bug.

### Verificar types JSDoc ao mudar shape de response
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** `types/Chapter.js` e `types/Item.js` definem `@property` que serve como contrato interno. Se o response muda mas os types não, futuros devs vão confiar nos types desatualizados.
**O que checar:** Após qualquer breaking change no response, verificar se os arquivos em `types/` foram atualizados.

### `toc_id`, `content_id`, `chapter_id` — IDs múltiplos em features de cache
**Aprendido em:** cached-ldi-toc (2026-03-18)
**Contexto:** Feature de TOC cache introduziu `toc_id` e `content_id` além do `chapter_id` já existente. Composables que fazem lookup por ID precisam aceitar todos os campos possíveis.
**O que checar:** Em features que introduzem cache ou Read Models no backend, verificar se o front-student trata múltiplas chaves de ID possíveis.
