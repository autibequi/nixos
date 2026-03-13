---
name: monolito/go-migration
description: Use when creating, modifying, or reviewing any database migration in the monolito Go codebase — covers file creation, goose directives, schema prefix, idempotency, Down obrigatório, indexes, e execução local. Applies to new migrations, fixing existing migrations, and adding/altering columns or indexes.
---

# Estratégia Go Migration Pattern

## Overview

Migrations usam [Goose](https://github.com/pressly/goose). Rodam automaticamente no startup da aplicação via `MigrateUpSharedDb` ou `MigrateUp` em cada app. Toda migration precisa de `Up` e `Down` — sem exceção.

## Criando o Arquivo

```sh
make new-migration HORIZONTAL=<horizontal> NAME=<descricao_snake_case>
# ex:
make new-migration HORIZONTAL=ldi NAME=add_cached_content_to_courses
make new-migration HORIZONTAL=objetivos NAME=create_locations_table
```

O arquivo gerado fica em `migration/<horizontal>/` com nome no formato:
`YYYYMMDDHHmmSS_<descricao>.sql`

## Estrutura Obrigatória

```sql
-- +goose Up
-- +goose StatementBegin
-- SQL do Up aqui
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- SQL do Down aqui (reverte o Up exatamente)
-- +goose StatementEnd
```

## Regras de Escrita

### 1. Sem schema prefix

O `search_path` já é configurado pelo goose via `WithSchema`. Não prefixar tabelas com o schema:

```sql
-- ✅ correto
CREATE TABLE IF NOT EXISTS my_table (...);
ALTER TABLE royalty_snapshots ADD COLUMN IF NOT EXISTS ...;

-- ❌ errado — schema redundante
CREATE TABLE IF NOT EXISTS ldi.my_table (...);
```

### 2. Sempre idempotente

```sql
CREATE TABLE IF NOT EXISTS my_table (...);
DROP TABLE IF EXISTS my_table;

ALTER TABLE courses ADD COLUMN IF NOT EXISTS cached_content JSONB DEFAULT NULL;
ALTER TABLE courses DROP COLUMN IF EXISTS cached_content;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_my_table_col ON my_table USING btree (col);
DROP INDEX CONCURRENTLY IF EXISTS idx_my_table_col;
```

### 3. Down reverte o Up na ordem inversa

```sql
-- Up: cria tabela, depois indexes
-- Down: remove indexes, depois tabela

-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS my_table (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID NOT NULL REFERENCES courses(id),
    name TEXT NOT NULL,
    data JSONB DEFAULT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_my_table_course_id ON my_table USING btree (course_id);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP INDEX CONCURRENTLY IF EXISTS idx_my_table_course_id;
-- +goose StatementEnd
-- +goose StatementBegin
DROP TABLE IF EXISTS my_table;
-- +goose StatementEnd
```

### 4. ADD COLUMN simples

```sql
-- +goose Up
-- +goose StatementBegin
ALTER TABLE courses ADD COLUMN IF NOT EXISTS cached_content JSONB DEFAULT NULL;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS structure_updated_at TIMESTAMP DEFAULT NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE courses DROP COLUMN IF EXISTS cached_content;
ALTER TABLE courses DROP COLUMN IF EXISTS structure_updated_at;
-- +goose StatementEnd
```

## Tipos Comuns

| Necessidade | Tipo PostgreSQL |
|---|---|
| ID primário | `UUID DEFAULT gen_random_uuid() PRIMARY KEY` |
| Referência | `UUID NOT NULL REFERENCES schema.table(id)` |
| Texto livre | `TEXT` |
| Texto curto/enum | `VARCHAR(255)` |
| JSON flexível | `JSONB DEFAULT NULL` |
| Booleano | `BOOLEAN NOT NULL DEFAULT false` |
| `created_at` / `updated_at` | `TIMESTAMP DEFAULT NOW()` — **sempre com DEFAULT NOW()** |
| Inteiro | `INT` / `BIGINT` / `BIGSERIAL` (auto-increment) |
| Float | `FLOAT` |

## Executando Localmente

```sh
# Subir todas as migrations de um horizontal (todos os verticals)
make migrate-up HORIZONTAL=ldi SCHEMA=ldi

# Desfazer a última migration
make migrate-down HORIZONTAL=ldi SCHEMA=ldi

# As migrations rodam também automaticamente no startup:
make run       # ou docker compose up
```

> `make migrate-up/down` roda em todos os bancos verticais (medicina, concursos, militares, oab, etc.)

## Como as Migrations São Executadas no Startup

Cada app chama a migration no seu arquivo raiz (`<app>.go`):

```go
// Apps com banco compartilhado (maioria)
migration.MigrateUpSharedDb(config, "ldi", vertical, migration.WithSchema("ldi"))

// Apps com banco próprio
migration.MigrateUp(db, "pag_professores_"+vertical, appName)
```

Isso significa que **toda migration nova roda automaticamente** na próxima vez que a aplicação subir — local ou em produção.

## Erros Comuns

- **Schema prefix nas tabelas**: desnecessário e redundante — o `search_path` já está configurado
- **Sem `IF NOT EXISTS` / `IF EXISTS`**: migration falha se rodar duas vezes
- **Down vazio ou incompleto**: impossível reverter em emergência
- **Index sem `CONCURRENTLY`**: bloqueia a tabela durante criação em produção
- **`CONCURRENTLY` dentro de transaction block**: não funciona — cada `CREATE/DROP INDEX CONCURRENTLY` precisa do seu próprio `StatementBegin/End`
- **`created_at`/`updated_at` sem `DEFAULT NOW()`**: campos ficam nulos na inserção
