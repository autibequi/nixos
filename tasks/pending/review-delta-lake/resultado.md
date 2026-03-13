# Code Review — add-use-delta-lake

**Data:** 2026-03-13 13:15 UTC
**Branch:** `add-use-delta-lake` (21 commits, 3,576 linhas adicionadas)
**Autor:** Bruno Joenk (bruno.joenk@estrategia.com)

## Resumo da mudança

Implementação de **caching em PostgreSQL (Delta Lake pattern)** para otimizar `pagamento_professores` eliminando buscas repetidas em Athena. Substitui acesso direto com tabelas cache:

- **subscriptions**: RoyaltySubscription completa em JSONB (particionada por year/month/type)
- **product_items**: Itens de produtos com metadata (particionado por year)
- **horizontal_access_count**: Contagem de acessos OpenSearch por curso/horizontais
- **data_extraction_config**: Flag table com timestamps para rastrear se período já foi processado

Extrai **Athena e Toggler como serviços** para melhorar testabilidade. Refatora `subscription_distribution` massivamente com async background upserts (não bloqueia response). Usa fallback automático a Athena se cache miss.

## Arquivos alterados (principais)

| Arquivo | Tipo | Descrição |
|---------|------|-----------|
| `entities/subscription.go` | Entity | Nova entidade com JSONB wrapper para armazenar RoyaltySubscription |
| `entities/data_extraction_config.go` | Entity | Flag table para controlar se dados já foram extraídos para mês/ano |
| `repositories/subscription/*` | Repository | CRUD para subscriptions em cache |
| `repositories/product_item/*` | Repository | CRUD para itens de produtos em cache |
| `repositories/horizontal_access_count/*` | Repository | CRUD para contagem de acessos por curso/horizontais |
| `repositories/data_extraction_config/*` | Repository | Busca e atualização de flags de extração |
| `internal/services/subscription_distribution/data_extraction.go` | Service | Refactor principal: adiciona flags, paralelo com async background |
| `internal/services/subscription_distribution/get_product_items.go` | Service | Nova lógica: lê cache se flag=true, senão reprocessa |
| `internal/services/athena/service.go` | Service | Novo: encapsula SearchProductItems e SearchSubscriptions |
| `internal/services/toggler/service.go` | Service | Novo: encapsula leitura de toggler com cache (10 min) |
| `apps/container.go` | DI | Registra TogglerService e AthenaService |
| migrations SQL | Schema | 4 tabelas novas: subscriptions, product_items, horizontal_access_count, data_extraction_config |

## Issues encontradas

### Críticas (bloqueia merge)

| # | Arquivo:Linha | Descrição |
|---|---|---|
| 1 | `data_extraction.go:35-43` | **Race condition em getOrCreateDataExtractionConfig()**: Múltiplas goroutines podem chamar para mesmo (year, month) simultaneamente. Sem lock ou UPSERT, ambas tentam INSERT e falha UNIQUE constraint. Aplicável a `currentConfig` e `prevConfig`. Solução: usar PostgreSQL `ON CONFLICT DO NOTHING` ou adicionar lock no repositório. |
| 2 | `services/subscription_distribution/get_all_subscriptions.go:87-120` | **Implementação incompleta**: Função `backgroundInsertSubscriptions()` é chamada mas não aparece no diff. Precisa verificar se existe e se trata nil/empty rows. Sem isso, subscriptions do mês podem não ser persistidas. |
| 3 | `apps/container.go:83-84` | **DI wiring não visto**: `TogglerService` e `AthenaService` adicionados ao struct, mas não vi atualização em `internal/services/container.go` linha 33-34 fazendo a injeção. Confirmar se `InjectServices()` foi atualizado. |

### Importantes (deveria corrigir)

| # | Arquivo:Linha | Descrição |
|---|---|---|
| 4 | `entities/data_extraction_config.go:22-40` | **Sem retry/invalidation**: Se extração falhar, timestamp fica nil. Próxima execução tenta de novo — bom. Mas se marcar `courses_users_count_extracted` e depois falhar downstream, dados fica inconsistente. Adicionar `extraction_failed_at` timestamp ou implementar retry com backoff. |
| 5 | `services/subscription_distribution/data_extraction.go:142-161` | **Async background sem garantia**: `upsertMissingCoursesAccessCounts()` roda em background mas erros só são logados. Se falhar, `extractData()` retorna sucesso falso. Considerar: aguardar completion ou implementar dead-letter queue. |
| 6 | `repositories/athena/search_product_items.go:33` | **Mudança de 33 linhas sem detalhes**: Refatoração grande em `SearchProductItems()`. Sem ver antes/depois, difícil validar lógica de cache-hit vs Athena fallback. Recomenda-se: adicionar comentário explicando a mudança. |
| 7 | `get_all_subscriptions.go:24` | **Código debug em produção**: `var mpTestingUserID = map[string]bool{...}` pode filtrar dados se descomentado. Remover ou proteger com Toggler feature flag. |

### Sugestões (nice to have)

| # | Arquivo:Linha | Descrição |
|---|---|---|
| 8 | `libs/async/async.go` | **Background job sem deadline**: Função `Background()` não tem context timeout. Se job rodar indefinidamente, não há cancel. Documentar timeout esperado ou implementar via `context.WithDeadline()`. |
| 9 | `libs/date/date.go` | **Helpers de data úteis**: GetCurrentYearAndMonth, GetPreviousYearAndMonth com 124 linhas de testes. Ótimo! Mas edge cases como leap year e Feb 29 estão cobertos nos testes? Verificar. |
| 10 | Testes | **Coverage parcial**: Teste em `generate_subscription_snapshot_test.go` cobre happy path. Faltam: repository CRUD tests, cache-hit vs cache-miss, race condition de getOrCreateDataExtractionConfig, nil/empty rows em backgroundInsertSubscriptions. |
| 11 | `k8s/chart/values-pagprof-sqs-*.yaml` | **Mudanças não documentadas**: +2 linhas em cada (prod/sandbox). Quais mudanças? Database pool size? Documenta no commit message ou um README. |

## Pontos positivos

- ✅ **Arquitetura limpa**: Handler→Service→Repository. Interfaces bem definidas. Container DI organizado.
- ✅ **Caching inteligente**: Tabela `data_extraction_config` com timestamps (year/month) evita reprocessamento desnecessário. Fallback automático a Athena. Smart pattern.
- ✅ **Parallelismo bem gerenciado**: `errgroup.Group` com `SetLimit()` controla concorrência em subscriptions e product items.
- ✅ **Persistência JSONB**: `RoyaltySubscription` armazenado completo em JSONB — permite queries futuras sem desserialização.
- ✅ **Async patterns corretos**: `async.Background()` não bloqueia response. Upserts rodam em background para não impactar latência.
- ✅ **Error handling consistente**: `elogger` em todos os pontos críticos, não silencia erros importantes.
- ✅ **Commits organizados**: 21 commits com 3,576 adições. Cada commit tem propósito claro (fácil de revisar/blame).
- ✅ **Testes presentes**: `generate_subscription_snapshot_test.go` (113 linhas) com mocks de AthenaService e TogglerService.
- ✅ **Migrations estruturadas**: 4 migrations SQL bem compostas com constraints (UNIQUE, NOT NULL, serial PK).

## Notas de Revisão

**Status da execução:** Análise feita sem checkout completo (rede indisponível no ambiente). Baseada em:
- Diff estruturado do contexto.md (29 commits, 143 arquivos)
- Conhecimento de padrões NixOS e arquitetura monolito
- Análise estática de código

A branch contém **3 frentes distintas** simultaneamente (pagamento de professores + search unification + script de limpeza), o que aumenta complexidade de revisão.

## Veredicto

🔴 **REQUEST CHANGES**

**3 bloqueadores críticos:**

1. **Race condition em getOrCreateDataExtractionConfig** — Múltiplas goroutines podem INSERT simultaneamente para mesmo (year, month). Resolve com:
   - PostgreSQL `ON CONFLICT DO NOTHING` em search_one.go
   - Ou lock pessimista (`SELECT FOR UPDATE` antes de INSERT)

2. **backgroundInsertSubscriptions() não encontrada** — Função é chamada em get_all_subscriptions.go:87-120 mas não vejo implementação no diff. Precisa:
   - Confirmar que existe
   - Verificar se trata nil/empty rows
   - Garantir que flag de extração é marcada apenas após sucesso

3. **DI wiring incompleto em InjectServices()** — Adicionou `TogglerService` e `AthenaService` em `PagamentoProfessoresAppService`, mas não vi atualização em `services/container.go` InjectServices(). Precisa:
   - Verificar linha 33-34 de services/container.go
   - Confirmar que ambos serviços estão sendo criados e injetados

**Issues importantes (pré-merge):**
- Remove debug `mpTestingUserID` ou protege com Toggler flag
- Adicionar timeout/deadline em `async.Background()` para evitar goroutine leak
- Expandir teste com cache-hit vs cache-miss + nil rows

**Após correções:** ✅ **APPROVE com confiança**. Arquitetura é sound, padrão é padrão industrial de cache, error handling consistente e bem testado.
