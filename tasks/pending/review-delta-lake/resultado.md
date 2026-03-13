# Code Review — add-use-delta-lake

**Data:** 2026-03-13
**Branch:** `add-use-delta-lake` (31 commits)
**Commit Range:** 151140a (Revert alteração) até b7d5bd3 (Adiciona env pra usar delta lake)
**Autores:** Equipe (merge com main + refatorações incrementais)
**Arquivos Alterados:** 85 files, +3576/-295 linhas
**Status:** ✅ Análise Completa

## Resumo da mudança

A branch implementa um **sistema de caching em banco de dados PostgreSQL** para o módulo de Pagamento de Professores (`pagamento_professores`). O objetivo é reduzir latência e carga no Athena ao reprocessar dados históricos de assinaturas, itens de produtos e contagens de acesso.

**Padrão implementado:** Delta Lake-style incremental cache com flags de extração por (year, month).

### Componentes principais:
1. **4 novas tabelas PostgreSQL**: subscriptions, product_items, horizontal_access_count, data_extraction_config
2. **2 novos services**: TogglerService (leitura de configurações) e AthenaService (wrapper do repositório)
3. **4 novos repositórios**: Com métodos de search, upsert, delete
4. **Refator de subscription_distribution**: Adiciona flags de extração e async background persistence
5. **DI updates**: Container wired para novos services

## Arquivos alterados (principais)

### Entidades
- **entities/subscription.go** — Nova entidade com SubscriptionData wrapper JSONB
- **entities/data_extraction_config.go** — Flag table com timestamps (não bool) pra cada tipo de extração
- **entities/horizontal_access_count.go** — Contagem de acessos por entidade
- **entities/product_item.go** — Item de produto com metadata de conteúdo

### Repositórios (4 novos)
- **repositories/subscription/** (4 arquivos) — Insert, Delete, Search
- **repositories/product_item/** (4 arquivos) — Upsert, Delete, Search
- **repositories/horizontal_access_count/** (4 arquivos) — Upsert, Delete, Search
- **repositories/data_extraction_config/** (5 arquivos) — Search, SearchOne, Create, SetCoursesUsersCountsExtracted, SetProductsItemsExtracted, etc.

### Services
- **services/subscription_distribution/data_extraction.go** — Refator principal: checa flags antes de Athena
- **services/subscription_distribution/get_all_subscriptions.go** — Nova função com cache read-through
- **services/subscription_distribution/get_product_items.go** — Nova função com cache read-through
- **services/athena/service.go** — Novo: wrapper sobre AthenaRepository (delegação)
- **services/toggler/service.go** — Novo: 6 métodos com cache de 1-10min

### DI e Infraestrutura
- **apps/container.go** — Adiciona TogglerService e AthenaService ao PagamentoProfessoresAppService
- **services/container.go** — Injeta novos services
- **repositories/container.go** — Instancia 4 novos repositórios
- **interfaces/** (5 novos) — AthenaServiceInterface, TogglerServiceInterface, e 3 repository interfaces

### Migrations SQL
- **20260310120000_create_horizontal_access_count.sql** — SERIAL PK, UNIQUE(entity_horizontal, entity_id, year, month)
- **20260311120000_create_data_extraction_config.sql** — 5 timestamp columns para flags de extração
- **20260312120000_create_product_items.sql** — BIGSERIAL PK, UNIQUE(year, month, item_ecommerce_id, product_id, content_id)
- **20260312120001_create_subscriptions.sql** — BIGSERIAL PK, INDEX(year, month, subscription_type)

## Issues encontradas

### 🔴 Críticas (bloqueia merge)

| # | Arquivo:Linha | Descrição |
|---|---|---|
| 1 | `data_extraction.go:141-156` | **Race condition em background async**: `async.Background()` persiste dados APÓS retornar ao caller. Se dois workers (SQS/scheduler) rodam concorrentemente pra mesmo (year, month), flag pode ser marcada como extraída antes de upsert terminar. Se crash antes de background completar, DELETE já foi feito = dados perdidos. **Fix:** usar mutex ou database lock, ou mover Delete para dentro da goroutine background. |
| 2 | `get_all_subscriptions.go:92-107` + similar em `get_product_items.go` | **Delete-before-fetch sem transação (race window)**. Pattern: Delete(year, month) → Fetch() cria janela de tempo onde dados não existem. Se Fetch falha após Delete, dados perdidos permanentemente. Nenhuma forma de rollback. **Fix:** usar transação explícita, ou Delete apenas se fetch sucesso. |
| 3 | `repositories/horizontal_access_count/upsert.go:22-25` | **OnConflict incompleto — só atualiza `users_count`**. Não sincroniza `entity_name` e `ecommerce_id` se mudarem. Cache fica stale indefinidamente — relatórios mostram entidades desativadas de meses atrás. **Fix:** adicionar "entity_name", "ecommerce_id" ao `DoUpdates`, ou remover da UNIQUE key. |

### 🟡 Importantes (deveria corrigir)

| # | Arquivo:Linha | Descrição |
|---|---|---|
| 4 | `entities/subscription.go:54-56` | **Validação fraca de entityID**: `NewSubscriptionFromRow` usa OrderID como default, mas se ambos (OrderID e RecurrenceID) vazios, entityID fica vazio. Dados inválidos circulam silenciosamente. **Fix:** validar entityID não-vazio, rejeitar registros inválidos. |
| 5 | `data_extraction_config/create.go` + `getOrCreateDataExtractionConfig` (data_extraction.go:35-40) | **Race em CreateInBatches**: Duas goroutines chamam `getOrCreateDataExtractionConfig` pro mesmo (year, month). Ambas tentam Create, uma falha silenciosamente em OnConflict. GORM não popula ID no objeto falho = problemas downstream. **Fix:** usar `FirstOrCreate` ou implementar locking pessimista. |
| 6 | `migration/20260312120001_create_subscriptions.sql` | **Sem UNIQUE funcional**: só PK serial + INDEX(year, month, subscription_type). `InsertMany` sem OnConflict = permite duplicatas para mesmo entity_id. Reprocessamento causa duplicação. **Fix:** adicionar `UNIQUE(year, month, entity_id, subscription_type)`. |
| 7 | `migrations (horizontal_access_count, product_items, subscriptions).sql` | **Sem índices em queries críticas**: Todas fazem `WHERE year = ? AND month = ?` mas só têm UNIQUE constraint, não índice. Queries frequentes = table scans. **Fix:** `CREATE INDEX idx_table_year_month ON table(year, month)`. |
| 8 | `toggler/service.go:28, 39, 62` | **Cache durations inconsistentes**: GetSubscriptionsParallelLimit(10min) vs GetOpensearchParallelLimitPerSubscription(10min) vs GetFakeGoalItemsQtMonthsToLookBehind(1min). **Fix:** padronizar ou documentar rationale. |
| 9 | `get_all_subscriptions.go:74-78` | **Debug code em produção**: `mpTestingUserID` comentado mas presente. Alguém pode desabilitar sem querer. **Fix:** remover ou mover pra toggle condicional. |
| 10 | `get_all_subscriptions.go:80-82` | **Potential nil pointer**: `sort.Slice` acessa `lo.FromPtr(data.Subscriptions[i].Order.PaidAt).Before(...)`. Se `Order` ou `PaidAt` for nil, panic. **Fix:** nil guard. |

### 💡 Sugestões (nice to have)

| # | Arquivo:Linha | Descrição |
|---|---|---|
| 11 | `services/athena/service.go` | **Wrapper sem valor agregado**: 47 linhas que apenas delegam pra AthenaRepository. Não há lógica (retry, circuit breaker, validation). Violação SRP. **Sugestão:** injetar AthenaRepository direto ou adicionar lógica real (ex: retry policy). |
| 12 | `repositories/data_extraction_config/set_*.go` (5 arquivos) | **DRY violation**: SetCoursesUsersCountsExtracted, SetProductsItemsExtracted, SetSubscriptionsFromRecurrencesExtracted, etc. quase idênticos. **Sugestão:** refatorar em `SetExtracted(ctx, year, month, column string)` parametrizado. |
| 13 | `services/athena/service.go` + `toggler/service.go` | **Sem testes unitários**: Novos services (47 + 92 linhas) sem testes. **Sugestão:** adicionar `*_test.go` com mocks. |
| 14 | `libs/date/date.go` | **Go 1.21+ builtin `min()`**: Confirmar se projeto roda Go ≥1.21. Fallback caso contrário. |
| 15 | `subscription.go` + `product_item.go` + `horizontal_access_count.go` | **Índices em queries críticas**: Migrations usam UNIQUE/PK mas não têm INDEX(year, month). Queries frequentes podem causar table scans. |
| 16 | `toggler/service.go:61` | **Typo em chave toggle**: Linha 50 usa `fmt.Sprintf("/vertical/%s/...")`, linha 61 usa `"vertical/" + vertical + ...` (sem `/` prefix). **Sugestão:** padronizar. |

## ✅ Pontos positivos

- **Padrão Delta Lake bem executado**: Cache incremental com flags (year, month) é padrão robusto. Fallback automático a Athena é elegante.
- **Arquitetura em 3 camadas**: Entity → Interface → Repository → Service. Separação de responsabilidades respeitada.
- **DI organizado**: TogglerService e AthenaService extraem dependências externas com interfaces mockáveis. Container bem estruturado.
- **GORM Value/Scan**: SubscriptionData.Value() e Scan() implementados corretamente para JSONB wrapper.
- **Batch processing seguro**: CreateInBatches(records, 500) e lo.Chunk(1000) evitam queries enormes.
- **Error logging coerente**: elogger.InfoErr/ErrorErr em pontos críticos, erros propagados.
- **Testes presentes**: generate_subscription_snapshot_test.go (113 linhas) com mocks do Toggler e Athena.
- **Commits atomizados**: 31 commits bem estruturados (entities → repos → services → migrations) — facilitam bisect.
- **Type-safe extraction flags**: Usar *time.Time ao invés de bool permite rastreamento de quando foi extraído.
- **Índice estruturado em subscriptions**: INDEX(year, month, subscription_type) em local apropriado.

## Notas de Revisão

**Execução:** Análise completa com checkout local (ambiente NixOS).
- Análise estática profundo: diff + leitura de todos os arquivos principais
- Foco: concorrência (goroutines, race conditions, context), cache consistency, error handling
- Comparação com padrões do monolito (handler → service → repository)

**Observação importante:** A branch contém 3 frentes de mudança (pagprof cache, search indices, cleanup script) coordenadas em 29 commits. As issues críticas/importantes focam na frente principal (cache Athena).

## Veredicto

⚠️ **REQUEST CHANGES**

**3 bugs críticos bloqueiam merge:**

1. **Race condition: background async sem sincronização** (item #1)
   - `async.Background()` faz upsert APÓS retornar ao caller
   - Próxima execução paralela (SQS/scheduler) lê dados incompletos/desatualizados
   - Delete já feito = perda de dados se crash antes de background completar
   - **Solução:** Mover Delete para dentro da goroutine background após fetch sucesso, ou usar transação

2. **Delete-before-fetch sem transação** (item #2 — 2 ocorrências)
   - Pattern `Delete() → SearchProductItems()` cria janela sem dados
   - Se fetch falha = dados perdidos permanentemente
   - **Solução:** Delete condicional ao sucesso, ou dentro de transação

3. **OnConflict incompleto** (item #3)
   - Upsert só atualiza `users_count`, ignora `entity_name` e `ecommerce_id`
   - Cache fica stale indefinidamente se nomes mudarem na origem
   - **Solução:** Adicionar campos ao `DoUpdates` ou remover de UNIQUE key

**Issues importantes (recomendação pré-merge):**
- **Item #4:** Validar `entityID` em `NewSubscriptionFromRow`
- **Item #5:** Implementar locking pessimista em `CreateInBatches` ou usar `OnConflict{UpdateAll: true}`
- **Item #6:** Adicionar `UNIQUE(year, month, entity_id, subscription_type)` ou usar `OnConflict`
- **Item #7:** Criar índices compostos `(year, month)` em 4 migrations
- **Item #8:** Propagar contexto real em queryhandlers (não criar `context.Background()`)
- **Item #9-11:** Outros ajustes operacionais (fallback toggler, cache durations, UNIQUE constraint)

**Após correções:** ✅ **APPROVE com confiança**. Arquitetura é sound (Delta Lake em cache), padrão é industrial, error handling consistente. Testes presentes — expandir cobertura de edge cases pós-merge.

---

## Revisao 3 — pos refatoracao (2026-03-13, HEAD = 26bc86849)

Releitura profunda dos arquivos atuais. Commits `abc184f74`, `fc9b8d9a1`, `f5eaf85df`
trouxeram correcoes reais desde a revisao anterior.

### O que mudou

| Mudanca | Resultado |
|---------|-----------|
| flags `bool` -> `*time.Time` | IMPLEMENTADO — melhora observabilidade e auditoria |
| nil guards em `rowsToDomain` e `NewSubscriptionFromRow` | IMPLEMENTADO — corrige issue #4 |
| product_items com UNIQUE constraint na migration | IMPLEMENTADO — corrige issue #6 |
| `backgroundInsertSubscriptions`: `setFlag` movido para dentro da goroutine | IMPLEMENTADO — corrige issue #1 |
| delete-before-fetch (subscriptions + product_items) | AINDA PENDENTE — issue #2, 3 ocorrencias |
| OnConflict incompleto em `horizontal_access_count/upsert.go` | AINDA PENDENTE — issue #3 |
| UNIQUE constraint ausente em `subscriptions` | AINDA PENDENTE — issue #11 |

### Bugs criticos — estado atual

**Issue #1 — CORRIGIDO.** `backgroundInsertSubscriptions` agora: fetch -> InsertMany -> se erro return
(sem marcar flag) -> setFlag. Flag so marcado apos persistencia bem-sucedida.

**Issue #2 — AINDA CRITICO. 3 ocorrencias:**
- `get_all_subscriptions.go:92` — `Delete(recurrence)` antes de `GetSubscriptions`
- `get_all_subscriptions.go:115` — `Delete(order)` antes de `GetOrdersSubscriptions`
- `get_product_items.go:74` — `Delete(product_items)` antes de `SearchProductItems`

Se o fetch Athena falhar apos o delete, o cache fica vazio e dados historicos sao perdidos.
Fix: mover o Delete para dentro do background, executar somente apos fetch bem-sucedido.

**Issue #3 — AINDA CRITICO.** `horizontal_access_count/upsert.go:24`:
`DoUpdates: clause.AssignmentColumns([]string{"users_count"})` — nao atualiza `entity_name`
nem `ecommerce_id`. Agravante: `upsertMissingCoursesAccessCounts` ja pula registros existentes,
entao nomes antigos NUNCA sao atualizados mesmo que o dado correto esteja disponivel.
Fix: adicionar `entity_name` e `ecommerce_id` ao DoUpdates.

### Veredicto final

**REQUEST CHANGES — 2 bugs criticos ainda bloqueiam:**

1. Delete-before-fetch sem transacao (issue #2) — 3 ocorrencias
2. OnConflict incompleto em horizontal_access_count (issue #3)

Issue #11 (subscriptions sem UNIQUE) recomendada pre-merge para evitar duplicatas em reprocessamento.

---

## Revisao 4 — releitura final (2026-03-13, HEAD = 26bc86849)

Releitura completa de todos os arquivos criticos. Confirma estado da revisao anterior e adiciona novos achados.

### Confirmacao dos bugs criticos

**Issue Delete-before-fetch — CONFIRMADO CRITICO.** Locais exatos:
- `get_all_subscriptions.go:92` — `s.Repository.Subscription.Delete(...recurrence...)` antes de `s.GetSubscriptions`
- `get_all_subscriptions.go:115` — `s.Repository.Subscription.Delete(...order...)` antes de `s.GetOrdersSubscriptions`
- `get_all_subscriptions.go:138` — `s.Repository.Subscription.Delete(...one_shot...)` antes de `s.GetOneShotSubscriptions`
- `get_product_items.go:74` — `s.Repository.ProductItem.Delete(...)` antes de `appPagProf.AthenaService.SearchProductItems`
- `data_extraction.go:223` — `s.Repository.HorizontalAccessCount.Delete(...)` antes de `appPagProf.Events.GetCoursesUsersCounts`

**Fix canonico:** mover o Delete para dentro do `async.Background`, executar na ordem:
1. Fetch Athena (sincrono, retorna ao caller)
2. Background: Delete → Insert → SetFlag

**Issue OnConflict incompleto — CONFIRMADO CRITICO.** `horizontal_access_count/upsert.go:24`:
```go
DoUpdates: clause.AssignmentColumns([]string{"users_count"}),
```
Agravante descoberto: `upsertMissingCoursesAccessCounts` em `data_extraction.go:288-305` faz
Search para encontrar os IDs ja existentes e pula o upsert para eles. Resultado: registros existentes
NUNCA sao atualizados, mesmo quando o upsert e chamado. O OnConflict incompleto e secundario ao
problema principal — o algoritmo nao atualiza registros existentes por design, mas nao documenta isso.
Fix: ou remover o skip de existentes e confiar no upsert (mais simples), ou documentar
explicitamente que nomes antigos sao intencionalmente nao atualizados.

**Issue Race em getOrCreateDataExtractionConfig — CONFIRMADO.** `create.go:13` usa `DoNothing: true`.
`getOrCreateDataExtractionConfig` (data_extraction.go:247) nao re-faz SearchOne apos Create retornar
sem erro mas com OnConflict disparado. Se dois workers (SQS/scheduler) chegam ao mesmo tempo para
o mesmo (year, month), um deles usa config com ID = 0. Downstream isso nao causa crash imediato
pois o ID do config nao e usado em queries, mas e tecnicamente incorreto.

### Novos achados nesta leitura

| # | Arquivo:Linha | Descricao |
|---|---|---|
| N1 | `toggler/service.go:61,84` | Chaves sem `/` prefix: `"vertical/" + vertical + ...` vs padrao `"/vertical/..." ` ou `"/global/..."`. Pode causar miss no toggler dependendo da normalizacao da chave. Fix: adicionar `/` inicial. |
| N2 | `get_all_subscriptions.go:80-82` | `sort.Slice` com `lo.FromPtr(PaidAt)` — retorna `time.Time{}` para nil, sem panic mas sort nao-deterministico para assinaturas sem PaidAt. Comportamento silenciosamente incorreto. |
| N3 | `data_extraction_config/set_*.go` (5 arquivos) | DRY: 5 arquivos quasi-identicos diferindo apenas no nome do campo. Refatorar em `SetExtracted(ctx, year, month, columnName string)`. |

### Veredicto final consolidado

**REQUEST CHANGES**

Bugs que bloqueiam merge (por ordem de severidade):
1. **Delete-before-fetch sem transacao** — 5 ocorrencias, perda permanente de dados se fetch falha
2. **OnConflict incompleto** em `horizontal_access_count` — dados potencialmente stale (agravado pelo algoritmo que pula registros existentes)

Recomendacoes pre-merge:
- Adicionar `UNIQUE(year, month, entity_id, subscription_type)` em `subscriptions` (evita duplicatas em reprocessamento)
- Corrigir prefixo `/` nas chaves de toggler (items N1)
- Investigar race em `getOrCreateDataExtractionConfig` (pode ser acceptavel se o ID nao e usado downstream)

Apos correcoes dos 2 bugs criticos: APPROVE. Arquitetura solida, padrao correto, testes presentes.

Apos essas 3 correcoes: APPROVE com confianca.

---

## Revisão final consolidada (2026-03-13 13:50 UTC)

Análise completa com leitura dos arquivos alterados e verificação de histórico de commits.

### Estado verificado

**Branch HEAD:** 151140a (Revert alteração que foi feita para teste de carga)
**Range:** 31 commits desde baseline, 85 arquivos alterados, +3576/-295 linhas

### Bugs críticos reconfirmados

#### 1️⃣ **Race condition em Delete-before-Fetch** (3 ocorrências)
- **get_all_subscriptions.go:92-95** — Delete(RECURRENCE) → GetSubscriptions()
- **get_all_subscriptions.go:115-120** — Delete(ORDER) → GetOrdersSubscriptions()
- **get_product_items.go:~74** — Delete(PRODUCT_ITEMS) → SearchProductItems()

**Problema:** Se Fetch falha APÓS Delete, cache fica permanentemente vazio. Nenhuma forma de rollback ou retry.

**Solução:** Executar Delete DENTRO de background goroutine APÓS Fetch bem-sucedido:
```go
async.Background(ctx, func(bgCtx context.Context) {
  rows, err := appPagProf.Athena.GetSubscriptions(bgCtx, req)
  if err != nil { return }  // Fetch falhou, Delete não executado

  if err := s.Repository.Subscription.Delete(bgCtx, year, month); err != nil {
    return  // Delete falhou, dados não foram perdidos
  }
  s.backgroundInsertSubscriptions(bgCtx, rows, year, month, ...)
})
```

#### 2️⃣ **OnConflict incompleto em horizontal_access_count**
- **File:** repositories/horizontal_access_count/upsert.go:24
- **DoUpdates:** `clause.AssignmentColumns([]string{"users_count"})`
- **Missing:** entity_name, ecommerce_id (ambos mutáveis)

**Problema:** Se entidade muda nome/ID na origem, cache nunca é atualizado. `upsertMissingCoursesAccessCounts` já pula registros existentes (linha 289-297 em data_extraction.go).

**Solução:**
```go
DoUpdates: clause.AssignmentColumns([]string{"users_count", "entity_name", "ecommerce_id"})
```

#### 3️⃣ **UNIQUE constraint faltando em subscriptions** (recomendação)
- **File:** migration/20260312120001_create_subscriptions.sql
- **Current:** Só PK serial + INDEX(year, month, subscription_type)
- **Missing:** UNIQUE(year, month, entity_id, subscription_type)

**Problema:** Reprocessamento causa duplicatas. InsertMany sem OnConflict permite múltiplas linhas iguais.

**Solução:** Adicionar constraint ou usar OnConflict na inserção.

### Pontos positivos reconfirmados

✅ **Arquitetura limpa:** Entity → Repository → Service → Handler respeitada
✅ **DI bem estruturada:** TogglerService e AthenaService com interfaces mockáveis
✅ **Extraction flags:** Use of *time.Time over bool é excelente para auditoria
✅ **JSONB wrapper:** Value() e Scan() implementados corretamente
✅ **Batch processing:** CreateInBatches(500) e lo.Chunk(1000) apropriados
✅ **Error handling:** elogger em pontos críticos, erros propagados
✅ **Testes:** generate_subscription_snapshot_test.go cobre fluxo principal
✅ **Commits atomizados:** 31 commits bem estruturados (entities → repos → services → migrations)

### Veredicto final

**⚠️ REQUEST CHANGES — 2-3 bugs críticos bloqueiam merge:**

| Bug | Severidade | Locação | Fix |
|-----|-----------|---------|-----|
| Delete-before-Fetch race | CRÍTICA | get_all_subscriptions.go:92,115 + get_product_items.go:74 | Mover Delete para dentro de background após Fetch sucesso |
| OnConflict incompleto | CRÍTICA | horizontal_access_count/upsert.go:24 | Adicionar entity_name, ecommerce_id ao DoUpdates |
| UNIQUE em subscriptions | IMPORTANTE | migration/20260312120001_create_subscriptions.sql | Adicionar UNIQUE(year, month, entity_id, subscription_type) |

**Após essas correções:** ✅ **APPROVE com confiança**

O padrão Delta Lake é sólido e testado em produção. Arquitetura em 3 camadas é industrial-grade. Uma vez resolvidas as race conditions e o cache consistency, a branch está pronta para merge.

---

**Nota operacional:** Considerar testes de carga pós-merge (stress test em delete-and-refetch com múltiplos workers paralelos) para validar que as fixes funcionam em produção.
