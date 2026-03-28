---
name: monolito/go-handler
description: Use when creating, modifying, or refactoring any HTTP handler (endpoint) in the monolito Go codebase — covers struct definitions, binding, validation, vertical resolution, service delegation, response format, and route registration. Applies to new handlers, modifying existing handlers, changing service calls in handlers, and updating route wiring.
---

# Estratégia Go Handler Pattern

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

## Templates

Antes de executar, ler os templates de referência neste diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/handler.md` | Anatomia completa de um handler (request/response structs, swagger, bind, validate, context, service call, response) + handler struct pattern |
| `templates/patterns.md` | Tags de validação, patterns de erro HTTP, resposta com paginação |

## Overview

Handlers are thin HTTP adapters. All business logic lives in services. The handler's only jobs are: bind → validate → resolve vertical → call service → return response.

## Anatomy of a Handler File

O handler segue uma estrutura fixa de 8 passos: request struct → response struct → swagger → bind → validate → context/vertical → service call → response.

→ Ver anatomia completa em `templates/handler.md`

## Handler Struct (handler.go)

Cada pacote de handlers tem um `handler.go` com o struct `Handler` e construtor `NewMeuHandler`.

→ Ver pattern completo em `templates/handler.md`

## Regras de Ouro

| Regra | Detalhe |
|---|---|
| Structs no topo do arquivo | Request e response definidos antes do handler, no mesmo `.go` |
| Swagger obrigatório | Sempre no bloco de comentário imediatamente acima da func |
| Sem lógica de negócio | Cálculos, validações de domínio, decisões → service |
| `common.Err*` para mensagens | Nunca string inline — usar constantes de `apps/bo/internal/handlers/common/constants.go` |
| Vertical sempre via appcontext | `appcontext.GetVertical(ctx)` para indexar o service map |
| `structs.HTTPResponse` como envelope | `Data`, `Meta` (paginação) e `Err` são os únicos campos |

## Tags de Validação, Erros e Paginação

Patterns de validação, erros HTTP (`NewHTTPError`, `HTTPError` struct) e resposta paginada.

→ Ver exemplos completos em `templates/patterns.md`

## Wiring — Checklist Obrigatório

Após criar o handler, execute todos os passos abaixo:

- [ ] **`handler.go`** do pacote — se for um pacote novo, criar struct `Handler` + construtor
- [ ] **Container do app** — instanciar o novo handler e registrar a rota

**Se for handler do BO (`apps/bo/internal/handlers/ldi/container.go` ou equivalente):**
```go
// 1. Instanciar o handler no Init()
myNewHandler := my_new_package.NewMyHandler(h.appsServices, clients)

// 2. Registrar a rota no grupo correto
ldi.GET("/my-resource/:id", myNewHandler.GetByID, somePermission("ldi.my_resource.get"))
ldi.POST("/my-resource", myNewHandler.Create, somePermission("ldi.my_resource.create"))
```

**Se for handler do app principal (`apps/ldi/ldi.go`, `apps/bff/bff.go` etc.):**
```go
// Registrar diretamente no grupo de rotas do ServerRoutes
apiGroup.GET("/my-resource/:id", handlers.myHandler.GetByID)
```

> A rota deve usar kebab-case. O método do handler deve estar no grupo de permissões correto.
> Verificar se o pacote do handler precisa ser importado no arquivo de container/rota.

## Erros Comuns

- **Lógica no handler**: condicional de negócio, cálculo, transformação → move pro service
- **String de erro inline**: usar `common.Err*`
- **Struct de request/response no final do arquivo** ou em arquivo separado → sempre no topo do mesmo `.go`
- **Esquecer swagger**: obrigatório em todo handler público
- **Não usar vertical**: esquecer `appcontext.GetVertical(ctx)` ao indexar `AppsServices`
