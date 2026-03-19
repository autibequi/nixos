---
name: estrategia/opensearch
description: Consulta o cluster OpenSearch da Estrategia. Use quando precisar montar queries, explorar índices, debugar busca, ou gerar links para o Dev Console. Contém mapeamento completo de todos os índices e exemplos prontos.
---

# estrategia/opensearch: Consultar Cluster OpenSearch

## Objetivo

Responder perguntas sobre dados no OpenSearch da Estrategia, montar queries prontas para executar, e gerar links diretos para o Dev Console.

---

## Cluster

| | |
|---|---|
| **Base URL** | `https://vpc-opensearch-search-sandbox-7vky3ic62zgpwwdyxxzssw6d7i.us-east-2.es.amazonaws.com` |
| **Dev Console** | `https://vpc-opensearch-search-sandbox-7vky3ic62zgpwwdyxxzssw6d7i.us-east-2.es.amazonaws.com/_dashboards/app/dev_tools#/console` |
| **Versão** | OpenSearch 7.10.2 (compatível com ES 7.x) |
| **Auth** | Sem autenticação (VPC interno) |
| **Acesso via container** | `curl -s "$BASE/<índice>/_search"` funciona direto |

---

## Verticais

Todos os índices seguem o padrão `<tipo>-<vertical>-v<versão>`.

| Vertical | Slug |
|---|---|
| Vestibulares | `vestibulares` |
| Concursos | `concursos` |
| Militares | `militares` |
| OAB | `oab` |
| Carreiras Jurídicas | `carreiras-juridicas` |
| Medicina | `medicina` |

---

## Índices e Mapeamentos

### `questions-<vertical>`

Questões de provas. Maior índice — vestibulares tem 9.4M docs.

| Campo | Tipo | Valores conhecidos |
|---|---|---|
| `id` | keyword | UUID/numérico |
| `body` | text | Enunciado da questão (full-text) |
| `body_support` | text | Texto de apoio |
| `status` | keyword | `APPROVED`, `CREATED`, `ANSWER_REQUESTED`, `ISSUE_FOUND`, `DELETED`, `PENDING_APPROVAL` |
| `answer_type` | keyword | `MULTIPLE_CHOICE`, `DISCURSIVE`, `TRUE_OR_FALSE` |
| `difficulty_level` | keyword | `EASY`, `MEDIUM`, `HARD`, `VERY_EASY`, `VERY_HARD` |
| `answer_status` | keyword | `FINAL_ANSWER_SHEET`, `TEMPORARY_ANSWER_SHEET`, `CANCELED`, `IN_REVIEW`, `OUTDATED` |
| `is_public` | boolean | |
| `is_unlisted` | boolean | |
| `max_exam_year` | integer | Ano máximo das provas que contêm a questão |
| `author_id` | keyword | |
| `teacher_id` | keyword | |
| `video_solution_id` | keyword | |
| `forum_id` | keyword | |
| `key_pedagogical_order` | keyword | |
| `alternatives` | nested | Alternativas (a, b, c, d, e) |
| `classifications` | nested | Classificações pedagógicas |
| `exams` | nested | Provas que contêm esta questão |
| `solutions` | nested | Resoluções |

**Índices por vertical (versão atual):**
- `questions-vestibulares-v16` — 9.4M docs / 2.4GB
- `questions-militares-v3` — 4.3M docs / 1GB
- `questions-carreiras-juridicas-v14` — 4.3M docs / 1GB
- `questions-oab-v3` — 78K docs
- `questions-concursos-v3` — 2K docs
- `questions-medicina-v1` — 7 docs

---

### `contents-<vertical>`

Conteúdos (aulas, PDFs, etc).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | Nome do conteúdo (full-text) |
| `type` | keyword | Tipo do conteúdo |
| `path` | keyword | Caminho hierárquico |
| `parent_id` | keyword | |
| `is_private` | boolean | |
| `authors` | keyword | |
| `created_at` | date | |
| `classifications` | nested | |
| `ecommerce_item_ids` | keyword | |
| `duplication_from_id` | keyword | |

**Índices:** `contents-vestibulares-v18` (229K), `contents-carreiras-juridicas-v15` (580K), `contents-concursos-v5`, `contents-militares-v5`, `contents-oab-v5`, `contents-medicina-v1`

---

### `educational-contents-<vertical>`

Conteúdos educacionais enriquecidos (com cursos, goals, LDIs).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | |
| `description` | text | |
| `type` | keyword | |
| `type_content` | keyword | |
| `course_type` | keyword | |
| `published` | boolean | |
| `published_at` | date | |
| `slug` | keyword | |
| `lp_id` | keyword | ID da landing page |
| `lp_slug` | keyword | |
| `lp_title` | text | |
| `lp_free_text` | text | |
| `is_macro` | boolean | |
| `is_explorer_enabled` | boolean | |
| `scholarity_level` | text | |
| `remuneration_from` | integer | |
| `remuneration_up_to` | integer | |
| `authors` | nested | |
| `classifications` | nested | |
| `courses` | nested | |
| `goals` | nested | |
| `ldis` | nested | |
| `trails` | nested | |
| `location` | nested | |
| `classes` | nested | |
| `sections` | nested | |
| `shelves` | nested | |
| `ecommerce_item_ids` | keyword | |
| `all_course_ids` | keyword | |
| `all_course_types` | keyword | |
| `all_ecommerce_item_ids` | keyword | |

**Índices:** `educational-contents-vestibulares-v2` (243K), `educational-contents-carreiras-juridicas-v2` (1.1M), `educational-contents-concursos-v2`, `educational-contents-militares-v2`, `educational-contents-oab-v2`, `educational-contents-medicina-v1`

---

### `exams-<vertical>`

Provas/simulados.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `number` | keyword | Número da prova |
| `year` | keyword | Ano da prova |
| `is_completed` | boolean | |
| `questions_ids` | keyword | IDs das questões |
| `questions_ids_size` | integer | Quantidade de questões |
| `questions_number` | integer | |
| `created_at` | date | |
| `updated_at` | date | |
| `deleted_at` | date | |
| `catalogs` | object | |
| `catalogs_data` | nested | |

**Índices:** `exams-vestibulares-v4` (66K), `exams-concursos-v4` (798K), `exams-militares-v1` (24K), `exams-carreiras-juridicas-v4` (21K), `exams-oab-v4` (1K)

---

### `courses-<vertical>`

Cursos.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | |
| `course_type` | keyword | |
| `published` | boolean | |
| `published_at` | date | |
| `parent_id` | keyword | |
| `children_ids` | keyword | |
| `version` | text | |
| `ecommerce_item_ids` | keyword | |
| `authors` | nested | |
| `children` | nested | |
| `classes` | nested | |
| `classifications` | nested | |
| `goals` | nested | |

**Índices:** `courses-vestibulares-v13` (200K), `courses-carreiras-juridicas-v13` (413K), `courses-militares-v13` (21K), `courses-concursos-v3`, `courses-oab-v3`, `courses-medicina-v1`

---

### `goals-<vertical>`

Metas/concursos alvo (ex: FUVEST, TJ-SP, etc).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | |
| `details` | text | |
| `image` | text | |
| `lp_id` | keyword | |
| `lp_slug` | keyword | |
| `lp_title` | text | |
| `lp_free_text` | text | |
| `is_macro` | boolean | |
| `is_explorer_enabled` | boolean | |
| `scholarity_level` | text | |
| `remuneration_from` | integer | |
| `remuneration_up_to` | integer | |
| `published_at` | date | |
| `parent_ids` | keyword | |
| `all_course_ids` | keyword | |
| `all_course_types` | keyword | |
| `all_ecommerce_item_ids` | keyword | |
| `courses` | nested | |
| `ldis` | nested | |
| `trails` | nested | |
| `products` | nested | |
| `classifications` | nested | |
| `location` | nested | |

**Índices:** `goals-vestibulares-v24` (9.5K), `goals-concursos-v18` (8.1K), `goals-militares-v24` (1.2K), `goals-carreiras-juridicas-v24` (87K), `goals-oab-v15` (208), `goals-medicina-v1`

---

### `classifications-<vertical>`

Árvore de classificações pedagógicas (matérias, assuntos, bancas...).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | |
| `parent_id` | keyword | |
| `path_id` | text | Caminho de IDs |
| `path_name` | text | Caminho legível ex: `Instituição[??]Estratégia Vestibulares[??]Provas de Nivelamento[??]2ª Prova` |
| `path_deep` | integer | Profundidade (1=raiz) |
| `order_index` | long | |
| `pinned_position` | long | |
| `has_questions` | boolean | |
| `has_children` | boolean | |
| `has_children_with_questions` | boolean | |
| `aliases` | nested | Aliases/sinônimos |

**Índices:** `classifications-vestibulares-v5` (3.6K), `classifications-concursos-v6` (868K), `classifications-militares-v1` (3.1K), `classifications-carreiras-juridicas-v5` (17K), `classifications-oab-v6` (1.4K), `classifications-medicina-v1`

---

### `blocks-<vertical>`

Blocos de conteúdo (exercícios, listas, etc).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `item_id` | keyword | |
| `data` | text | Conteúdo principal (full-text) |
| `simple_data` | text | Versão simplificada |

**Índices:** `blocks-vestibulares-v2` (158K), `blocks-carreiras-juridicas-v2` (468K), `blocks-militares-v1` (111K), `blocks-concursos-v5` (3.8K), `blocks-oab-v5` (391), `blocks-medicina-v1`

---

### `ldis-<vertical>`

LDIs (Listas de Desenvolvimento Individual).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | |
| `course_type` | keyword | |
| `published` | boolean | |
| `published_at` | date | |
| `ecommerce_item_ids` | keyword | |
| `authors` | nested | |
| `chapters` | nested | |
| `classifications` | nested | |
| `goals` | nested | |

**Índices:** `ldis-vestibulares-v15` (19K), `ldis-carreiras-juridicas-v15` (231K), `ldis-militares-v15` (15K), `ldis-concursos-v6` (3.1K), `ldis-oab-v4` (786), `ldis-medicina-v1`

---

### `products-<vertical>`

Produtos para venda/ecommerce.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `name` | text | |
| `created_at` | date | |
| `items` | nested | Itens do produto |

**Índices:** `products-vestibulares-v1` (54K), `products-carreiras-juridicas-v1` (160K), `products-militares-v1` (22K), `products-concursos-v1`, `products-oab-v1`, `products-medicina-v1`

---

### `landing-pages-<vertical>`

Landing pages de metas/concursos.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | |
| `title` | text | |
| `slug` | keyword | |
| `id_objetivo` | keyword | |
| `free_text` | text | |
| `titulo_pacotes_e_cursos` | text | |
| `created_at` | date | |
| `published_at` | date | |
| `updated_at` | date | |
| `objetivo` | nested | |
| `products` | nested | |

**Índices:** `landing-pages-carreiras-juridicas-v8` (1.3K), `landing-pages-vestibulares-v8` (441), `landing-pages-militares-v8` (235), `landing-pages-concursos-v15` (130), `landing-pages-oab-v13` (116), `landing-pages-medicina-v1`

---

### `user-orders-<vertical>`

Pedidos de usuários (assinaturas/compras).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | ID do usuário |
| `orders` | nested | Pedidos ativos |
| `legacy_orders` | nested | Pedidos legados |

**Índices:** `user-orders-vestibulares-v3` (299K), `user-orders-carreiras-juridicas-v3` (987K), `user-orders-militares-v1` (185K), `user-orders-concursos-v2` (1K), `user-orders-oab-v2`, `user-orders-medicina-v1`

---

### `user-classifications-<vertical>`

Classificações dos usuários (progresso pedagógico).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | keyword | ID do usuário |
| (estrutura nested de progresso) | | |

**Índices:** `user-classifications-vestibulares-v2`, `user-classifications-carreiras-juridicas-v3` (49K), `user-classifications-militares-v1`, `user-classifications-concursos-v1`, `user-classifications-oab-v1`, `user-classifications-medicina-v1`

---

### `trails-<vertical>`

Trilhas de estudo.

**Índices:** `trails-carreiras-juridicas-v6` (834), `trails-vestibulares-v4` (7), `trails-concursos-v2` (261), `trails-militares-v4`, `trails-oab-v2`

---

### Outros índices notáveis

| Índice | Docs | Descrição |
|---|---|---|
| `educational-blocks-multi-vertical-v1` | 1.17M / 2.3GB | Blocos educacionais cross-vertical |
| `intranet-appointments-multi-vertical-v5` | 362K | Agendamentos intranet |
| `ldi-course-structure-*` | vários | Estrutura de cursos dentro de LDIs |
| `ldi-course-chapters-structure-*` | vários | Capítulos de cursos LDI |
| `ldi-course-chapter-items-structure-*` | vários | Itens dentro de capítulos |
| `ldi-completed-documents-*` | vários | Documentos concluídos por usuários |
| `ldi-block-durations-*` | vários | Duração de blocos por usuário |
| `ldi-user-completed-documents-*` | vários | Docs completos por usuário |
| `course-book-structure-*` | vários | Estrutura de apostilas |
| `question-lists-*` | vários | Listas de questões |
| `.ds-questions-resolved-*` | centenas de M | Questões respondidas (data streams) — ENORME |
| `.ds-event-tracker-*` | milhões | Eventos de tracking |
| `cast-albums-*` | vários | Albums/podcasts |

---

## Como Responder Perguntas

### Fluxo padrão

1. Identificar vertical e tipo de dado pedido
2. Escolher índice correto da tabela acima
3. Montar query DSL
4. Executar via `curl` para validar e mostrar resultado
5. Gerar link do Dev Console

### Gerar link do Dev Console

O Dev Console não suporta deep link com query pré-preenchida via URL. Entregar:
- A query formatada para colar no console
- O link do console: `https://vpc-opensearch-search-sandbox-7vky3ic62zgpwwdyxxzssw6d7i.us-east-2.es.amazonaws.com/_dashboards/app/dev_tools#/console`

### Executar via curl (para validar)

```bash
BASE="https://vpc-opensearch-search-sandbox-7vky3ic62zgpwwdyxxzssw6d7i.us-east-2.es.amazonaws.com"
curl -s "$BASE/<índice>/_search" \
  -H 'Content-Type: application/json' \
  -d '<query DSL>'
```

---

## Queries de Referência

### Busca por texto em questões

```json
GET /questions-vestibulares-v16/_search
{
  "size": 5,
  "_source": ["id", "status", "answer_type", "difficulty_level"],
  "query": {
    "bool": {
      "must": [
        { "match": { "body": "fotossíntese" } }
      ],
      "filter": [
        { "term": { "status": "APPROVED" } },
        { "term": { "answer_type": "MULTIPLE_CHOICE" } }
      ]
    }
  }
}
```

### Filtrar por dificuldade

```json
GET /questions-militares-v3/_search
{
  "size": 10,
  "query": {
    "bool": {
      "filter": [
        { "term": { "difficulty_level": "HARD" } },
        { "term": { "status": "APPROVED" } }
      ]
    }
  }
}
```

### Contar por status (aggregation)

```json
GET /questions-vestibulares-v16/_search
{
  "size": 0,
  "aggs": {
    "por_status": { "terms": { "field": "status", "size": 10 } },
    "por_dificuldade": { "terms": { "field": "difficulty_level", "size": 10 } },
    "por_tipo": { "terms": { "field": "answer_type", "size": 10 } }
  }
}
```

### Buscar conteúdo por nome

```json
GET /contents-carreiras-juridicas-v15/_search
{
  "size": 5,
  "_source": ["id", "name", "type", "path"],
  "query": {
    "match": { "name": "direito penal" }
  }
}
```

### Buscar goal/concurso por nome

```json
GET /goals-carreiras-juridicas-v24/_search
{
  "size": 5,
  "_source": ["id", "name", "lp_slug", "remuneration_from", "remuneration_up_to"],
  "query": {
    "match": { "name": "TJ-SP" }
  }
}
```

### Buscar classificações (árvore pedagógica)

```json
GET /classifications-vestibulares-v5/_search
{
  "size": 10,
  "_source": ["id", "name", "path_name", "path_deep", "has_questions"],
  "query": {
    "match": { "name": "matemática" }
  }
}
```

### Ver estrutura de um documento específico

```json
GET /questions-vestibulares-v16/_doc/<id>
```

### Ver mapping de um índice

```json
GET /questions-vestibulares-v16/_mapping
```

### Listar todos os índices

```json
GET /_cat/indices?v&h=index,docs.count,store.size,health
```

### Count rápido

```json
GET /questions-vestibulares-v16/_count
{
  "query": { "term": { "status": "APPROVED" } }
}
```

### Range de data

```json
GET /contents-vestibulares-v18/_search
{
  "size": 5,
  "query": {
    "range": {
      "created_at": {
        "gte": "2024-01-01",
        "lte": "2024-12-31"
      }
    }
  }
}
```

### Nested query (ex: questões com classificação específica)

```json
GET /questions-vestibulares-v16/_search
{
  "size": 5,
  "query": {
    "nested": {
      "path": "classifications",
      "query": {
        "term": { "classifications.id": "<classification-id>" }
      }
    }
  }
}
```

---

## Dicas

- **Sempre usar `"size": 0`** em queries de aggregation para não trazer docs desnecessários
- **`_source`** para limitar campos retornados e economizar banda
- **`keyword`** → filtro exato (`term`). **`text`** → busca full-text (`match`)
- Campos `nested` precisam de `nested` query, não `term` direto
- Índices com `-v<N>` no final — sempre usar a versão mais alta disponível
- `.ds-questions-resolved-*` são data streams gigantes (50-80GB cada) — usar com cuidado, sempre com filtros
- Sem autenticação no cluster sandbox — qualquer query funciona sem headers de auth
