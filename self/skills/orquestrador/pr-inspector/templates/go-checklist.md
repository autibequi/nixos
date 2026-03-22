# Go Inspection Checklist

Checklist por camada para inspeção de código Go no monolito. Aplicar na ordem bottom-up.

---

## Migrations

- [ ] `-- +goose Up` e `-- +goose Down` presentes
- [ ] `IF NOT EXISTS` em CREATE TABLE/INDEX
- [ ] `IF EXISTS` em DROP TABLE/INDEX (no Down)
- [ ] Sem prefixo de schema (`public.`) — deixar o search_path resolver
- [ ] `CREATE INDEX CONCURRENTLY` para tabelas grandes (>1M rows)
- [ ] Tipos corretos: `TIMESTAMPTZ` (não `TIMESTAMP`), `JSONB` (não `JSON`), `BIGINT` para IDs
- [ ] `NOT NULL` com `DEFAULT` quando apropriado
- [ ] Foreign keys com `ON DELETE` explícito
- [ ] Migrations reversíveis — Down desfaz tudo que Up faz
- [ ] Naming: `YYYYMMDDHHMMSS_<descricao>.sql`

## Entities / Structs

- [ ] `TableName()` implementado
- [ ] GORM tags corretas (`gorm:"column:..."`)
- [ ] JSON tags em snake_case
- [ ] `Value()/Scan()` para tipos custom (JSONB, enum)
- [ ] Campos obrigatórios marcados com ponteiros ou validators
- [ ] `ToDomain()` presente se entity difere do domain model

## Interfaces

- [ ] Interface pública em `<app>/interfaces/`
- [ ] Interface interna (repo) em `<app>/internal/interfaces/`
- [ ] Métodos com `ctx context.Context` como primeiro parâmetro
- [ ] Return types consistentes (não misturar `*T` com `T`)
- [ ] Interface não é "fat" (>10 métodos indica split necessário)
- [ ] Mudanças backwards-compatible (método novo ok; assinatura alterada = breaking)

## Repositories

- [ ] Implementa interface declarada em `internal/interfaces/`
- [ ] Queries usam GORM scopes ou builder (não SQL concatenado)
- [ ] `scanners.JSONB` para campos JSONB
- [ ] Vertical context em queries multi-tenant
- [ ] Batch operations para inserts/updates em massa
- [ ] Connection check antes de queries críticas
- [ ] Error wrapping com contexto (`fmt.Errorf("finding aluno: %w", err)`)

## Services

- [ ] Struct unexported `serviceImpl`
- [ ] Construtor `NewService` retorna interface
- [ ] Dependências injetadas via construtor (repos, cache, clients)
- [ ] `ctx context.Context` como primeiro parâmetro em todos os métodos
- [ ] Error handling: erros propagados, não silenciados
- [ ] `elogger` para logging (não `log.Printf` ou `fmt.Println`)
- [ ] NewRelic segment em métodos não-triviais
- [ ] Sem acesso direto a repos de outros apps (usar `apps.Container`)
- [ ] Options struct para parâmetros opcionais (não 10+ args)
- [ ] Vertical via `appcontext.GetVertical(ctx)` quando necessário

## Handlers

- [ ] Request/response structs no topo do arquivo
- [ ] Swagger comments completos (Summary, Tags, Param, Success, Failure, Router)
- [ ] 8-step anatomy respeitada (bind → validate → context → service → response)
- [ ] `structs.HTTPResponse` como envelope de resposta
- [ ] `common.Err*` constantes para mensagens de erro (não strings inline)
- [ ] `appcontext.GetVertical(ctx)` para resolver service
- [ ] Sem lógica de negócio no handler
- [ ] Handler struct registrado no container com permissão correta
- [ ] Rota em kebab-case

## Workers

- [ ] Nome registrado em `libs/worker/handlers_names.go`
- [ ] Message struct com `job_id` (se usa JobTracking)
- [ ] `addHandler` (não `workerutils.AddNamedHandler` direto)
- [ ] `WithJobTracking` se aplicável
- [ ] DLQ handler que retorna nil
- [ ] Job criado no SERVICE, não no handler
- [ ] Loop SQS resiliente (continue on error, não abort)
- [ ] Mapeamento em `configuration/config_sqs.yaml`

## Tests

- [ ] Testes existem para services com lógica de negócio
- [ ] Mocks gerados (não manuais)
- [ ] `AssertExpectations(t)` no final
- [ ] Caminho feliz + caminho de erro testados
- [ ] Table-driven tests para variações
- [ ] Sem sleep/timeout hack — usar channels ou mocks
- [ ] Build tag `testing` se necessário

---

*Aplicar este checklist durante o Passo 4 da inspeção, adaptando ao contexto do PR.*
