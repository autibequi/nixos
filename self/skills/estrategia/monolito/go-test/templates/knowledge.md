# Knowledge Base — Go Test Patterns

Conhecimento acumulado sobre padrões de teste no monolito. **Este arquivo evolui com o tempo** — após cada sessão de teste significativa, adicionar novos patterns e armadilhas.

## Build Tags e Environment

### Tags de build
- `-tags testing` é obrigatório para testes que dependem de fixtures ou test helpers
- Arquivos com `//go:build testing` só são incluídos com essa tag
- Alguns pacotes têm `//go:build !testing` para excluir código de produção dos testes

### APP_ENV
- `APP_ENV=testing` carrega configurações de teste (DB, Redis, SQS mock)
- Sem essa variável, o app tenta conectar em serviços de produção
- Alguns testes de integração checam `os.Getenv("APP_ENV")` explicitamente

## Mock Patterns

### Mockery
- Mocks gerados via `mockery` (config em `.mockery.yaml` ou `Makefile`)
- Comando: `make mocks-<app>` (ex: `make mocks-ldi`, `make mocks-bo`)
- Mocks ficam em `apps/<app>/mocks/`
- Nunca editar mocks manualmente — sempre regenerar

### Mock Setup no Teste
```go
// Pattern padrão com testify
mockRepo := new(mocks.AlunoRepositoryMock)
mockRepo.On("FindByID", mock.Anything, int64(1)).Return(&domain.Aluno{ID: 1}, nil)

svc := myservice.NewService(mockRepo, opts)
result, err := svc.GetByID(ctx, 1)

mockRepo.AssertExpectations(t)
```

### Mock Pitfalls
- `mock.Anything` é genérico — use matchers específicos quando possível
- `On("Method", args...).Return(...)` — a ordem dos args deve ser exata
- `AssertExpectations(t)` verifica que todos os `On()` foram chamados
- Se interface adiciona método → mock fica inválido → regenerar

## Test Structure

### Suites (testify)
Alguns apps usam `testify/suite` para agrupar testes:
```go
type AlunoServiceTestSuite struct {
    suite.Suite
    svc     interfaces.AlunoService
    mockRepo *mocks.AlunoRepositoryMock
}

func (s *AlunoServiceTestSuite) SetupTest() {
    s.mockRepo = new(mocks.AlunoRepositoryMock)
    s.svc = myservice.NewService(s.mockRepo)
}

func TestAlunoServiceTestSuite(t *testing.T) {
    suite.Run(t, new(AlunoServiceTestSuite))
}
```

### Table-Driven Tests
Pattern comum para testar múltiplas variações:
```go
tests := []struct {
    name    string
    input   CreateOptions
    wantErr bool
}{
    {"valid", CreateOptions{Name: "test"}, false},
    {"empty name", CreateOptions{Name: ""}, true},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) { ... })
}
```

## Common Failure Patterns

### 1. Interface Signature Change
**Sintoma:** `too many arguments in call` ou `not enough arguments`
**Causa:** Interface mudou assinatura mas mock e/ou teste não foram atualizados
**Fix:** `make mocks-<app>` + atualizar `On()` calls no teste

### 2. Nil Map/Slice
**Sintoma:** `assignment to entry in nil map` ou unexpected nil
**Causa:** Struct inicializada sem campos obrigatórios
**Fix:** Inicializar map/slice no construtor ou setup do teste

### 3. Context Cancelled
**Sintoma:** `context canceled` ou `context deadline exceeded`
**Causa:** Teste não cria context adequado ou timeout muito curto
**Fix:** Usar `context.Background()` ou `context.WithTimeout()` com margem

### 4. Goroutine Leak
**Sintoma:** `leaktest` falha ou teste trava
**Causa:** Goroutine esperando em channel que nunca recebe
**Fix:** Garantir que channels são fechados ou têm timeout

### 5. Import Cycle
**Sintoma:** `import cycle not allowed in test`
**Causa:** Teste importa pacote que importa o pacote testado
**Fix:** Usar pacote externo (`package xxx_test`) ou reorganizar imports

## App-Specific Notes

### LDI
- Maior app, mais testes, mais mocks
- `make mocks-ldi` pode demorar ~30s
- Services usam `apps.Container` para acessar serviços de outros apps

### Pagamento Professores
- Testes dependem de fixtures específicas de royalties
- Delta Lake tests podem precisar de mock de S3/Parquet
- `APP_ENV=testing` critical para não tocar em dados reais

### BO
- Handlers testados via httptest + echo context
- Permissões mockadas no context do teste

## Padroes Avancados (William / time LDI)

### Integration tests com Postgres real (`pgtest`)
Preferir integration tests com DB real ao inves de mock de repo. Spin up via `pgtest` com migrations reais.

```go
func TestUpdatePDF(t *testing.T) {
    db := pgtest.NewDB(t)
    setup.Migrate(db)
    defer setup.Teardown(t)

    repo := course_chapter.NewRepository(db)
    // ... criar fixtures reais
}
```

### `.Maybe()` em mocks condicionais
Para mocks que podem ou NAO ser chamados dependendo da ordem de execucao:
```go
mockContentService.On("GetOne", mock.Anything, content).Return(pdf, nil).Maybe()
```
Sem `.Maybe()`, o testify falha se o mock nao for chamado.

### Validar o que NAO mudou
Asserts de campos imutraveis previnem regressoes silenciosas:
```go
assert.Equal(t, updated.ID, before.ID)          // ID nao mudou
assert.Equal(t, updated.CourseID, before.CourseID)  // CourseID nao mudou
assert.NotEqual(t, updated.MyDocsPdfID, before.MyDocsPdfID) // isso sim mudou
```

### Testes de seguranca
Para endpoints que nao devem vazar dados de usuarios desconhecidos:
```go
// Verifica que response 200 mesmo para email desconhecido (anti-enumeration)
res := t.DoRequest(echo.POST, "/auth/passwordless/request", ...)
t.Equal(http.StatusOK, res.StatusCode)
// Confirma que nenhum codigo foi gerado no cache
var attempts []map[string]interface{}
t.NoError(t.GetRedisInterface().GetData(context.Background(), emailKey, &attempts))
t.Equal(false, attempts[0]["succeeded"])
```

### Mock values reais > `mock.Anything`
`mock.Anything` em tudo torna o teste inutil — nao valida o contrato.
```go
// ERRADO — nao valida que o ID correto foi passado
mock.On("GetByID", mock.Anything, mock.Anything).Return(...)

// CERTO — valida que o ID especifico foi passado
mock.On("GetByID", mock.Anything, expectedID).Return(...)
```

### Subtests descritivos (ingles, behavior-focused)
```go
t.Run("should return error when pdf is not found", func(t *testing.T) { ... })
t.Run("should update pdf id when content is valid pdf", func(t *testing.T) { ... })
// NAO: t.Run("test1", ...) ou t.Run("erro", ...)
```

---

*Última atualização: 2026-03-22 — padroes avancados do time LDI/William*
*Atualizar este arquivo após cada sessão de debug/teste significativa.*
