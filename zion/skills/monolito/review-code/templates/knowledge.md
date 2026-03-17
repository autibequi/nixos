# Knowledge Base — Code Review Monolito

Conhecimento acumulado em reviews do monolito da Estratégia. **Este arquivo EVOLUI a cada review.**
Ao finalizar uma review, adicionar entries novas nas seções relevantes.

---

## Arquitetura Geral

### Estrutura de Apps
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Cada app tem `entities/`, `interfaces/`, `internal/services/`, `internal/repositories/`, `structs/`
**O que checar:** Novos repos/services seguem a estrutura? Estão no `Container`?

### AppServices Container
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Apps acessam outros apps via `s.AppServices.<App>[vertical]`. Ex: `s.AppServices.PagamentoProfessores[vertical]`
**O que checar:** Acesso sempre usa vertical do context? Nunca acessa repo de outro app diretamente?

### Verticals
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** O monolito é multi-tenant por vertical (medicina, concursos, etc). Vertical vem do `appcontext.GetVertical(ctx)`.
**O que checar:** Dados particionados por vertical onde necessário? Cache keys incluem vertical?

---

## Patterns de Concorrência

### errgroup.Group
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Usa `github.com/estrategiahq/backend-libs/errgroup` (wrapper do x/sync/errgroup). `SetLimit(n)` controla paralelismo.
**O que checar:** Goroutines escrevem em shared state? Se sim, usam mutex? Variáveis capturadas em closures são safe?

### async.Background
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `libs/async.Background(ctx, fn)` spawna goroutine com recover e context propagation. Usado pra writes não-críticos (cache, logs).
**O que checar:**
- Background fn pode falhar silenciosamente — erro é logado mas não propagado
- Se o background fn seta uma flag (ex: "extracted=true"), o que acontece se falhar no meio?
- Panic recovery inclui stack trace (melhorado no PR delta-lake)

### Mutex em structs compartilhadas
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `data.MutexProductItemsMap` protege maps compartilhados entre goroutines.
**O que checar:** Todo acesso a maps compartilhados está protegido? Lock/Unlock simétricos? Não usa Lock dentro de Lock (deadlock)?

---

## Patterns de Cache/Persistência

### Flag Check → Cache Hit/Miss
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Tabela `data_extraction_config` com flags `*time.Time`. Nil = não extraído, timestamp = extraído.
**O que checar:**
- Flag é setada DEPOIS do insert com sucesso (não antes)
- Cache miss faz `Delete` de dados stale antes de re-buscar → idempotente
- Race condition no `getOrCreate`: dois workers podem criar simultaneamente — mitigado por `OnConflict{DoNothing: true}`

### GORM Upserts
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Pattern `clause.OnConflict{Columns: [...], DoUpdates: clause.AssignmentColumns([...])}`. `CreateInBatches(records, 500)` pra bulk.
**O que checar:**
- Columns do OnConflict batem com UNIQUE constraint da migration?
- DoUpdates lista os campos que devem ser atualizados (não lista = DoNothing)?
- Batch size razoável (500 é padrão do projeto)?

### Delete + Insert (sem UNIQUE)
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Tabela `subscriptions` não tem UNIQUE — usa `Delete(year, month, type)` + `InsertMany`. Se o background insert crashar no meio, pode ter dados parciais.
**O que checar:** Tabela tem UNIQUE? Se não, o fluxo de delete+insert é atômico? Duplicatas são problema?

---

## Patterns de Domínio — pagamento_professores

### Fluxo subscription_distribution
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** SQS worker processa snapshots de royalties. Fluxo:
1. `extractData` → busca subscriptions, product items, course user counts
2. Paralleliza via errgroup
3. `injectUsersCountBySubscriptionItems` → busca LDI access counts via OpenSearch
4. Gera snapshot de distribuição
**O que checar:** Mudanças mantêm a ordem de execução? Dados dependentes são resolvidos antes do parallelismo?

### Subscription types
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** 3 tipos: `from_recurrence` (Athena recurrences), `from_order` (Athena orders), `one_shot` (Athena one-shot/vitalícios)
**O que checar:** Todos os 3 tipos tratados consistentemente? `IsOneShot` flag setada corretamente?

### Horizontais (cursos, LDIs)
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `horizontal_access_count` armazena contagem de acessos por entity (course ou ldi), particionado por (entity_horizontal, entity_id, year, month).
**O que checar:** Entity horizontal é string ("course", "ldi") — novas horizontais adicionadas precisam de tratamento.

### Toggler (feature flags)
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Toggler é o sistema de feature flags. Chaves com pattern `/vertical/<v>/...` ou `/global/...`. Leituras via `ReadKeyObjectWithCache` com TTL.
**O que checar:** TTL razoável? Chave com vertical quando necessário? Service layer encapsula (não chamar direto do handler)?

---

## Patterns de Dados

### JSONB no PostgreSQL
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Structs com `Value()/Scan()` implementados pra GORM serializar/deserializar JSONB. Ex: `scanners.MapStringInt`, `SubscriptionData`.
**O que checar:**
- `Value()` retorna `[]byte` (não string)
- `Scan()` trata `src == nil`
- Struct com `omitempty` pode perder zero-values na ida e volta (int 0, string "")

### ToDomain pattern
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Entities têm `ToDomain(ctx)` que converte pra struct de domínio. Pode retornar `nil` em caso de dados inválidos.
**O que checar:** Caller faz nil check no retorno de `ToDomain`? Se não, panic.

### CSV DateTime
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `athena.CSVDateTime` wrappa `time.Time` com `UnmarshalCSV/MarshalCSV`. Format: `"2006-01-02 15:04:05"`.
**O que checar:** Zero time handled? Ponteiro `*CSVDateTime` vs value?

---

## Patterns de SQL (Athena)

### Queries SQL no Athena
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Queries montadas com `fmt.Sprintf` — tabelas do Athena (S3-backed). Ex: `cursos_db.events`, `ecommerce_db.product_items`.
**O que checar:** IDs são UUIDs (safe pra interpolação). Se aceitar input do user, SQL injection? Chunking pra queries com muitos IDs (IN clause limit)?

### Column aliases
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** As 3 queries de subscription (recurrence, orders, one_shot) usam aliases padronizados: `period_start`, `period_end`, `period_in_months`.
**O que checar:** Aliases batem com CSV tags da struct `RoyaltySubscription`?

---

## Armadilhas Conhecidas

### Nil pointer em slice de ponteiros
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Quando repo retorna `[]*Entity`, items individuais podem ser nil se GORM encontrar row com erro de scan.
**O que checar:** Loop sobre slice de ponteiros tem nil guard? `for _, item := range items { if item == nil { continue } }`

### Background goroutine perde contexto de erro
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `async.Background` loga erro mas não propaga. Se o insert falhar, o caller já retornou sucesso.
**O que checar:** Isso é aceitável pro caso de uso? Eventual consistency ok? Ou precisa de garantia forte?

### Map write em goroutines
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Goroutines dentro de `errgroup` que escrevem em maps locais. Se o map é declarado fora do `eg.Go`, precisa de mutex.
**O que checar:** Map compartilhado entre goroutines? Mutex presente? Ou cada goroutine escreve em variável local?

---

## Libs do Monolito

### libs/date
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `GetCurrentYearAndMonth(t)`, `GetPreviousYearAndMonth(t)`, `GetPreviousMonth(t)` com clamping end-of-month.
**O que checar:** Usa essa lib em vez de `t.AddDate(0, -1, 0)` (que pode dar problema com end-of-month)?

### libs/databases/scanners
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** Custom GORM scanners pra tipos JSONB. Ex: `scanners.MapStringInt`.
**O que checar:** Novo tipo JSONB? Precisa de scanner? `Value()/Scan()` implementados?

### libs/async
**Aprendido em:** review de add-use-delta-lake (2026-03-13)
**Contexto:** `async.Background(ctx, fn)` — fire-and-forget com panic recovery. Propaga appcontext mas não propaga cancelation.
**O que checar:** Background fn acessa dados que podem ser GC'd após o caller retornar? Context timeout pode cortar a goroutine?
