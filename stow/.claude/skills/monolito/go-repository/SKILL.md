---
name: monolito/go-repository
description: Use when creating, modifying, or refactoring any repository in the monolito Go codebase — covers struct pattern, connection/transaction handling, GORM query building, entity definition with ToDomain, container registration, and error mapping. Applies to new repos, new methods on existing repos, moving methods between repos, and changing query logic.
---

# Estrategia Go Repository Pattern

## Templates

Antes de executar, ler os templates de referencia com patterns completos e exemplos de codigo:

| Arquivo | Conteudo |
|---|---|
| `templates/entity.md` | Struct GORM, TableName, ToDomain, JSONB/JSONBArray, ponteiro vs valor, conversor inverso |
| `templates/repository.md` | Estilos de struct, conexao/transacao, queries GORM (search, getone, create, paginacao) |
| `templates/wiring.md` | Interface do repositorio, container registration, erros de dominio |

## Overview

Repositories sao a unica camada que acessa banco de dados. Nao contem logica de negocio — so queries. Toda conversao de entidade para struct de dominio (via `ToDomain`) acontece no servico, nao aqui.

## Estrutura de Arquivos

```
<app>/
  entities/
    my_entity.go           # struct GORM + TableName() + ToDomain()
  internal/
    interfaces/
      my_repo.go           # interface do repositorio (usada pelo servico)
    repositories/
      my_domain/
        repository.go      # struct + construtor
        create.go          # um arquivo por metodo (ou agrupados se triviais)
        search.go
        get_one.go
      container.go         # registra todos os repos como interfaces
```

## Entity — Definicao (criar antes do repositorio)

A entity e o mapeamento direto da tabela. Sempre criada em `<app>/entities/` antes de escrever o repo. Inclui struct com tags `gorm:"column:..."`, `TableName()`, `ToDomain()`, e opcionalmente `FromDomain()`.

-> Ver patterns completos em `templates/entity.md`

## Struct do Repositorio e Queries

Dois estilos de struct (exported vs unexported) — usar o padrao ja adotado pelo app. Conexao sempre via `databases.Database`, com suporte a transacao via context. Queries GORM para search com filtros opcionais, getone com mapeamento de ErrRecordNotFound, create, e paginacao com count.

-> Ver patterns completos em `templates/repository.md`

## Interface, Container e Erros de Dominio

Interface declarada em `internal/interfaces/`, container registra todos os repos, erros tecnicos do GORM mapeados para erros de dominio em `structs/`.

-> Ver patterns completos em `templates/wiring.md`

## Logging

```go
elogger.ErrorErr(ctx, err).Stack().Msg("myRepo.MethodName")
elogger.ErrorErr(ctx, err).Stack().Str("id", id).Any("search", search).Msg("myRepo.Search")
```

## Wiring — Checklist Obrigatorio

Apos criar o repositorio, execute todos os passos abaixo:

- [ ] **`internal/interfaces/<repo>.go`** — declarar a interface do repositorio
- [ ] **`internal/repositories/<domain>/repository.go`** — struct + construtor
- [ ] **`internal/repositories/container.go`** — adicionar campo + instanciar no `NewContainer`
- [ ] **`make mocks-<app>`** — regenerar mocks para que os testes possam mockar o novo repo

## Regras de Ouro

| Regra | Detalhe |
|---|---|
| Sem logica de negocio | So SQL/GORM — decisoes de negocio ficam no servico |
| Sempre checar transacao | `ctx.Value(appcontext.XxxTxKey)` antes de `GetConnection` (se o repo suporta tx) |
| `TableName()` obrigatorio na entity | Define schema + tabela explicitamente |
| `ToDomain()` na entity | Conversao entity->struct e responsabilidade da entity, chamada pelo servico |
| ErrRecordNotFound mapeado | Nunca vazar erro do GORM para cima — mapear para erro de dominio |
| Registrar no Container | Todo novo repo entra em `repositories/container.go` como interface |
| Filtros opcionais com `if` | Nunca query com WHERE desnecessario — so adicionar condicao se o campo estiver preenchido |
