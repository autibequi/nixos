---
name: monolito/go-service
description: Use when creating, modifying, or refactoring any service in the monolito Go codebase — covers interface definition, method signatures, options structs, ToDomain conversion, proxy vs orchestration patterns, and unit testing with mocks. Applies to new services, new methods on existing services, moving methods between services, and changing service logic.
---

# Estratégia Go Service Pattern

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

## Templates

Antes de executar, ler os templates de referência neste diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/service.md` | Struct `serviceImpl`, construtor `NewService`, declaração de interfaces (pública e interna) |
| `templates/structs.md` | Assinatura de métodos, organização de structs (options, request, response) |
| `templates/patterns.md` | Patterns por cenário: proxy, lógica de negócio, cache Redis, orquestração, logging |
| `templates/test.md` | Estrutura de teste unitário com mocks e assertions |

## Overview

Serviços concentram toda a lógica de negócio. Repositories assumidamente corretos (apenas acesso a banco). Handlers não têm lógica. O serviço é o único lugar que deve ter cobertura de testes obrigatória — exceto métodos proxy óbvios.

## Estrutura de Arquivos

```
<app>/
  interfaces/                          # Interfaces PÚBLICAS (usadas por outros apps via apps.Container)
    <service_name>.go
  internal/
    interfaces/                        # Interfaces INTERNAS (repositories, usadas só dentro do app)
      <repo_name>.go
    services/
      <service_name>/
        service.go                     # struct serviceImpl + NewService
        create.go                      # um arquivo por método (ou agrupados se triviais)
        search.go
        create_test.go                 # testes focados em regras de negócio
  structs/
    <domain>.go                        # structs de request/response/options do serviço
```

## service.go — Struct, Construtor e Interface

Struct unexported `serviceImpl` + construtor `NewService` que retorna a interface pública. Interface pública em `<app>/interfaces/`, interface de repo em `<app>/internal/interfaces/`.

→ Ver templates completos em `templates/service.md`

## Assinatura de Métodos e Structs

Padrão: `ctx → params obrigatórios identificadores → options (modificadores opcionais)`. Structs organizadas por domínio em `<app>/structs/`.

→ Ver templates completos em `templates/structs.md`

## Cenários de Implementação

Quatro patterns principais conforme o tipo de método:

- **Proxy** — repassa para o repo, sem lógica, sem teste
- **Lógica de negócio** — validação/transformação, teste obrigatório
- **Cache Redis** — chave prefixada com vertical, hash dos params, set em background
- **Orquestração** — chama outros apps via `apps.Container`, nunca repos externos

Inclui também convenções de logging com `elogger`.

→ Ver templates completos em `templates/patterns.md`

## Testes — Estrutura

Package externo (`package myservice_test`), dependências mockadas com testify, foco em regras de negócio. Testar caminho feliz e caminho de erro.

→ Ver template completo em `templates/test.md`

## Wiring — Checklist Obrigatório

Após criar o serviço, execute todos os passos abaixo:

- [ ] **`interfaces/<service>.go`** — declarar interface pública (se outros apps precisarem)
- [ ] **`internal/services/<domain>/service.go`** — struct + construtor
- [ ] **`internal/services/container.go`** (`InjectServices`) — instanciar e atribuir ao `ldi.*` / app struct
- [ ] **`apps/container.go`** — adicionar o campo na struct `XxxAppService`
- [ ] **`make mocks-<app>`** — regenerar mocks

```go
// 1. apps/container.go — adicionar campo na XxxAppService
type MyAppService struct {
    ExistingService interfaces.ExistingServiceInterface
    MyNewService    interfaces.MyNewServiceInterface  // ← adicionar
}

// 2. internal/services/container.go (InjectServices ou equivalente)
app.MyNewService = mynewservice.NewService(repos, opts.Cache, opts.Clients)  // ← adicionar
```

> Para apps como LDI que usam `InjectServices`, o campo vai em `apps/container.go` na `LDIAppService`
> e a atribuição vai em `apps/ldi/internal/services/container.go`.
> Para outros apps (pagamento_professores, objetivos etc.), verificar onde os serviços são instanciados
> no `<app>.go` raiz do app.

## Regras de Ouro

| Regra | Detalhe |
|---|---|
| Interface obrigatória | Todo serviço expõe interface, nunca struct concreto |
| Interfaces públicas em `interfaces/` | Para injeção nos outros apps via `apps.Container` |
| Interfaces de repo em `internal/interfaces/` | Nunca expostas externamente |
| Structs em `<app>/structs/` | Organizadas por domínio, não por camada |
| Sem acesso a repo externo | Orquestrar via serviços, nunca via repos de outro app |
| Proxy não precisa de teste | Mas **deve** existir como serviço |
| Toda regra de negócio testada | Mock das dependências, foco no comportamento |
| Logging em todos os erros | `elogger.InfoErr` para esperados, `elogger.ErrorErr` para críticos |
