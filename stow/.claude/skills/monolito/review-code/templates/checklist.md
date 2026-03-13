# Checklist de Code Review — Monolito

Seguir esta ordem para análise sistemática. Marcar mentalmente cada item conforme analisa.

---

## 1. Visão macro (antes de olhar código)

- [ ] Quantos arquivos? Quantas linhas adicionadas/removidas?
- [ ] Quais apps/packages afetados?
- [ ] Tem migrations? Quantas tabelas novas/alteradas?
- [ ] Tem mudanças em interfaces (contratos)?
- [ ] Commit history: evolução faz sentido? Muitos fixups indicam incerteza?

## 2. Migrations (schema primeiro)

- [ ] `goose Up` e `goose Down` presentes e corretos?
- [ ] Tipos de coluna adequados (TIMESTAMPTZ, JSONB, TEXT, INT, UUID, SERIAL/BIGSERIAL)?
- [ ] UNIQUE constraints onde necessário?
- [ ] Índices pra queries frequentes?
- [ ] Ordem de migrations (dependências entre tabelas)?
- [ ] Naming consistente (snake_case, prefixo do schema)?

## 3. Entities

- [ ] GORM tags corretas (`column`, `primaryKey`, `autoIncrement`, `autoCreateTime`, `autoUpdateTime`)?
- [ ] `TableName()` implementado com schema correto?
- [ ] Tipos Go correspondem aos tipos SQL?
- [ ] JSONB fields têm `Value()/Scan()` (ou usam scanner de `libs/databases/scanners`)?
- [ ] `ToDomain()` presente se necessário? Nil-safe?

## 4. Interfaces

- [ ] Interfaces públicas em `<app>/interfaces/` (pra outros apps)?
- [ ] Interfaces internas em `<app>/internal/interfaces/` (repos)?
- [ ] Return types consistentes (ponteiro vs valor, slice vs nil)?
- [ ] Breaking changes em interfaces existentes?

## 5. Repositories

- [ ] Segue pattern do monolito (struct `repoImpl`, construtor `NewRepository`)?
- [ ] Registrado no `Container` (`repositories/container.go`)?
- [ ] SQL queries: injection safe? Performance ok?
- [ ] Upserts: `OnConflict` columns batem com UNIQUE constraint?
- [ ] `CreateInBatches` pra bulk operations?
- [ ] Error handling: erros do GORM propagados com contexto?

## 6. Services (core)

- [ ] `defer newrelic.FromContext(ctx).StartSegment(...)` em todo método?
- [ ] Error handling: erros logados E propagados (nunca silenciados)?
- [ ] Concorrência: `errgroup` com `SetLimit` quando faz I/O paralelo?
- [ ] Shared state protegido por mutex?
- [ ] `async.Background` pra writes não-críticos — falha é aceitável?
- [ ] Nil guards em ponteiros retornados por repos?
- [ ] Lógica de negócio correta? Edge cases?
- [ ] Performance: N+1 queries? Batch vs loop? Chunking pra queries grandes?

## 7. Testes

- [ ] Lógica de negócio tem testes?
- [ ] Edge cases cobertos (nil, empty, duplicatas)?
- [ ] Mocks corretos (testify)?
- [ ] Testes de integração pra queries complexas?
- [ ] Gaps identificados — quais cenários não estão cobertos?

## 8. Config/Infra

- [ ] Novos env vars/config necessários?
- [ ] K8s values atualizados (SQS, resources, etc)?
- [ ] Feature flags (toggler) necessários pra rollback?

## 9. Cross-cutting concerns

- [ ] Logging adequado (elogger.InfoErr vs ErrorErr)?
- [ ] Observabilidade: métricas/traces pra paths críticos?
- [ ] Segurança: input validation, SQL injection, auth checks?
- [ ] Backwards compatibility: mudanças quebram consumers existentes?

## 10. Knowledge check

- [ ] Aplicar todas as armadilhas do `templates/knowledge.md`
- [ ] Algum pattern novo que deveria ser adicionado ao knowledge?
