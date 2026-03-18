---
name: monolito/make-feature
description: Use when asked to implement, modify, or refactor any feature, endpoint, or functionality in the monolito codebase — orchestrates the full implementation flow in the correct order using the other monolito/* skills. Applies to new features, refactoring existing code, moving logic between layers/services, and any multi-layer change touching repository/service/handler.
---

# Estratégia — Nova Funcionalidade

## Overview

Skill de orquestração. Não duplica conteúdo das sub-skills — define a ordem de execução, os pontos de decisão e garante o wiring entre cada camada antes de avançar.

## Passo 0 — Entender o escopo antes de escrever qualquer código

Ler `/workspace/mnt/estrategia/monolito/STATE.md` para verificar posição atual, decisões técnicas anteriores e blockers conhecidos.

Antes de começar, responder:

1. **Qual app de domínio** concentra a regra de negócio? (ver index em CLAUDE.md)
2. **Qual BFF/BO** expõe o handler? (`bo/`, `bff/`, `bff_mobile/`)
3. **Precisa de migration?** (coluna nova, tabela nova)
4. **Precisa de repository novo?** (novo acesso ao banco)
5. **Precisa de service novo?** (nova lógica ou apenas método novo num service existente?)
6. **O service precisa de cache Redis?**
7. **O service orquestra outros apps?**
8. **Precisa de worker/consumer SQS?** (processamento assíncrono, bulk actions)

Somente após responder essas perguntas iniciar a implementação.

## Skills Aninhadas — Onde Encontrá-las

As skills abaixo estão em `.claude/skills/estrategia/monolito/`:

- `monolito/go-migration`
- `monolito/go-repository`
- `monolito/go-service`
- `monolito/go-handler`
- `monolito/go-worker`

Ao invocar: `Skill("monolito/go-migration")`

## Ordem de Execução

As etapas têm dependência sequencial — executar uma por vez, fazendo o wiring antes de avançar.

```
[1] Migration        → se precisar de coluna/tabela nova
[2] Entity           → struct GORM + TableName() + ToDomain()
[3] Repository       → interface interna + impl + registrar no container
[4] Service          → interface pública + impl + registrar no AppService + apps/container.go
[5] Mocks            → make mocks-<app>
[6] Testes           → cobrir regras de negócio do service
[7] Handler HTTP     → arquivo + swagger + registrar rota no BO/BFF
[7w] Worker SQS      → se precisar de processamento assíncrono (usar monolito/go-worker)
[8] Verificação      → make test-<app> + golangci-lint run
```

## Etapa 1 — Migration (se necessário)

**Skill:** `monolito/go-migration`

Executar se houver coluna ou tabela nova. Caso contrário, pular.

## Etapa 2 — Entity (se repositório novo)

**Skill:** `monolito/go-repository` (seção Entity)

Criar em `apps/<dominio>/entities/` antes do repositório.

## Etapa 3 — Repository (se necessário)

**Skill:** `monolito/go-repository`

Checklist obrigatório ao final:
- [ ] Interface em `internal/interfaces/`
- [ ] Implementação em `internal/repositories/<domain>/`
- [ ] Registrado em `internal/repositories/container.go`

## Etapa 4 — Service

**Skill:** `monolito/go-service`

Checklist obrigatório ao final:
- [ ] Interface pública em `<app>/interfaces/` (se outros apps consumirem)
- [ ] Implementação em `internal/services/<domain>/`
- [ ] Campo adicionado na `XxxAppService` em `apps/container.go`
- [ ] Instanciado em `internal/services/container.go` (InjectServices ou equivalente)

## Etapa 5 — Mocks

```sh
make mocks-<app>
```

Executar após qualquer nova interface (repo ou service). Necessário para os testes compilarem.

## Etapa 6 — Testes do Service

**Skill:** `monolito/go-service` (seção Testes)

- Testar toda regra de negócio com dependências mockadas
- Proxy óbvio não precisa de teste
- Pelo menos um teste de caminho de erro

## Etapa 7 — Handler

**Skill:** `monolito/go-handler`

Checklist obrigatório ao final:
- [ ] Structs de request/response no topo do arquivo
- [ ] Swagger antes da func
- [ ] Handler instanciado no container do BO/BFF
- [ ] Rota registrada no grupo correto com permissão adequada

## Etapa 7w — Worker SQS (se necessário)

**Skill:** `monolito/go-worker`

Executar se a feature precisar de processamento assíncrono (bulk actions, eventos, etc.). **Sempre usar jobtracking** para rastrear progresso. A criação do job acontece no service (etapa 4), nunca no handler HTTP.

Checklist obrigatório ao final:
- [ ] Nome do handler em `libs/worker/handlers_names.go`
- [ ] Struct da mensagem com `job_id` em `apps/<app>/structs/`
- [ ] JobType em `apps/jobtracking/structs/job_search.go`
- [ ] Service cria job + envia mensagens SQS
- [ ] Worker handler em `apps/<app>/internal/handlers/<domain>/worker.go`
- [ ] EventContainer com wiring (AddNamedHandler + WithJobTracking)
- [ ] Handler mapeado na fila SQS em `configuration/config_sqs.yaml`

## Etapa 8 — Verificação

```sh
make test-<app>
golangci-lint run
```

Não declarar a funcionalidade completa antes de ambos passarem.

Após a verificação passar: atualizar `/workspace/mnt/estrategia/monolito/STATE.md` com a feature implementada, decisões técnicas relevantes (ex: arquitetura escolhida, motivo de não usar cache, cross-app patterns), e qualquer blocker encontrado.

## Cross-App Dependencies

Quando um service precisa chamar serviços de outro app (ex: Objetivos chamando Cursos):

### No construtor do service

```go
type serviceImpl struct {
    repos   *repositories.Container
    apps    *apps.Container  // ← necessário para acessar outros apps
    redis   databases.Cache
}

func NewService(repos *repositories.Container, apps *apps.Container, redis databases.Cache) interfaces.MyServiceInterface {
    return &serviceImpl{repos: repos, apps: apps, redis: redis}
}
```

### Na chamada cross-app

```go
func (s serviceImpl) BuildReport(ctx context.Context, id string) (*structs.Report, error) {
    vertical := appcontext.GetVertical(ctx)
    // Acessar via apps.Container — NUNCA acessar repos de outro app
    course, err := s.apps.LDI[vertical].CourseService.GetByID(ctx, id)
    if err != nil {
        return nil, err
    }
    // ... usar course
}
```

### No InjectServices (wiring)

```go
// internal/services/container.go
app.MyService = myservice.NewService(repos, opts.Apps, opts.Cache)
//                                         ↑ passa apps.Container
```

### Nos testes (mock da dependência cross-app)

```go
// Criar mock do service do outro app
mockCourseService := mocks.NewCourseServiceInterface(t)
mockCourseService.On("GetByID", mock.Anything, "id-123").Return(courseFixture, nil)

// Montar apps.Container com o mock
testApps := &apps.Container{
    LDI: map[string]*apps.LDIAppService{
        "concursos": {CourseService: mockCourseService},
    },
}
svc := myservice.NewService(repos, testApps, redisCache)
```

## Regras que nunca mudam

- Lógica de negócio **sempre** no app de domínio, nunca no BFF/BO
- Handler **sempre** em `bo/`, `bff/` ou `bff_mobile/` — raramente dentro do app de domínio
- Serviços de outros apps acessados via `apps.Container`, nunca seus repositórios diretamente
- Wiring de cada camada feito **antes** de avançar para a próxima
