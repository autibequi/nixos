---
name: monolito/go-test
description: Use when running, debugging, analyzing, or fixing tests in the monolito Go codebase — covers test execution, failure analysis, mock validation, coverage reports, and fix proposals. Applies to running tests for a specific app/package, investigating test failures, checking mock freshness, and improving test coverage.
---

# Estratégia Go Test Pattern

## Templates

Antes de executar, ler os templates de referência neste diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/knowledge.md` | Padrões de teste do monolito, falhas comuns, convenções de mock, flags de build |

## Overview

O monolito usa `go test` com build tags (`-tags testing`), `APP_ENV=testing`, e paralelismo alto (`-p 16`). Mocks são gerados com `mockery` via Makefile targets (`make mocks-<app>`). Tests vivem no mesmo pacote (`_test.go`) ou em pacote externo (`package xxx_test`).

## Passo 1 — Identificar alvo

### Se recebeu app name, file path, ou test function:
Usar diretamente como alvo.

### Se recebeu "auto" ou nenhum argumento:
Detectar arquivos modificados na branch atual:

```bash
cd /home/claude/projects/estrategia/monolito
CHANGED=$(git diff --name-only origin/main -- '*.go' | grep -v '_test.go' | grep -v '/mocks/')
```

Mapear cada arquivo modificado para seu app e pacote de teste:
- `apps/<app>/internal/services/<svc>/create.go` → testar `apps/<app>/internal/services/<svc>/...`
- `apps/<app>/internal/handlers/<pkg>/handler.go` → testar `apps/<app>/internal/handlers/<pkg>/...`
- `apps/<app>/internal/repositories/<pkg>/repo.go` → testar `apps/<app>/internal/repositories/<pkg>/...`
- `libs/<pkg>/...` → testar `libs/<pkg>/...`

Apresentar ao dev:

```
Arquivos modificados na branch:
  apps/ldi/internal/services/aluno/create.go
  apps/ldi/internal/services/aluno/search.go

Pacotes de teste a rodar:
  ./apps/ldi/internal/services/aluno/...

Confirma? Ou quer testar algo específico?
```

## Passo 2 — Pre-flight

Verificar que o código compila antes de rodar testes:

```bash
cd /home/claude/projects/estrategia/monolito
go build -tags testing ./apps/<app>/...
```

Se falhar, analisar o erro e corrigir antes de prosseguir.

### Check de mock freshness

Comparar timestamps de interfaces vs mocks:

```bash
# Encontrar interface modificada
find apps/<app>/interfaces/ apps/<app>/internal/interfaces/ -name '*.go' -newer apps/<app>/mocks/ 2>/dev/null
```

Se encontrar interfaces mais novas que os mocks:

```
⚠️ Mocks potencialmente desatualizados:
  apps/ldi/interfaces/aluno_service.go (modificado após último make mocks-ldi)

Rodar `make mocks-<app>` antes de testar? (sim/não)
```

Se sim:
```bash
cd /home/claude/projects/estrategia/monolito
make mocks-<app>
```

Verificar se houve mudanças nos mocks:
```bash
git diff --stat apps/<app>/mocks/
```

## Passo 3 — Lint (opcional)

Se o dev pedir ou se houver falhas de compilação suspeitas:

```bash
cd /home/claude/projects/estrategia/monolito
golangci-lint run ./apps/<app>/... --timeout 5m
```

Apresentar apenas issues em arquivos modificados (filtrar output).

## Passo 4 — Rodar testes

### Comando base:
```bash
cd /home/claude/projects/estrategia/monolito
APP_ENV=testing go test -tags testing -v -p 16 -count=1 <paths>
```

### Variações:
| Flag | Quando usar |
|---|---|
| `-run <regex>` | Testar função específica (ex: `-run TestCreateAluno`) |
| `-cover` | Quando dev pedir relatório de cobertura |
| `-race` | Quando suspeitar de race condition |
| `-timeout 5m` | Testes que podem travar (workers, integração) |
| `-short` | Pular testes de integração marcados com `testing.Short()` |

### Se rodar todo o app:
```bash
APP_ENV=testing go test -tags testing -v -p 16 -count=1 ./apps/<app>/...
```

### Se rodar pacote específico:
```bash
APP_ENV=testing go test -tags testing -v -p 16 -count=1 ./apps/<app>/internal/services/<svc>/...
```

### Se rodar teste específico:
```bash
APP_ENV=testing go test -tags testing -v -p 16 -count=1 -run TestCreateAluno ./apps/<app>/internal/services/<svc>/...
```

## Passo 5 — Analisar falhas

Para cada teste falhando, classificar a causa raiz:

| Categoria | Sinais | Ação |
|---|---|---|
| **Mock mismatch** | `unexpected call`, `missing call`, `wrong number of args` | Interface mudou → regenerar mocks e atualizar teste |
| **Logic error** | Assertion falha com valores errados | Ler função sob teste + teste, identificar bug |
| **Setup issue** | `nil pointer`, `not initialized`, `no such table` | Dependência não injetada ou fixture incompleta |
| **Race condition** | `-race` detecta, ou teste falha intermitentemente | Goroutine sem sync, map concurrent write |
| **Timeout** | `test timed out` | Deadlock, canal sem consumidor, loop infinito |
| **Build tag** | `undefined: ...` | Faltou `-tags testing` ou arquivo sem build tag |

### Análise detalhada por falha:

Para cada teste falhando:
1. **Ler o teste** — entender o que ele espera
2. **Ler a função sob teste** — entender o que ela faz
3. **Comparar** — onde divergem?
4. **Classificar** — qual das categorias acima?
5. **Propor fix** — no teste, no código, ou nos mocks?

Apresentar ao dev:

```
Análise de Falhas — <N> testes falhando

  # Teste                    Categoria        Causa
  1 TestCreateAluno          Mock mismatch    Interface AlunService.Create mudou assinatura
  2 TestSearchAluno_NotFound Logic error      Service retorna []Aluno{} mas teste espera nil
  3 TestBulkUpdate           Race condition   Map shared entre goroutines sem mutex

Propostas de fix:
  1. Regenerar mocks (make mocks-ldi) + atualizar mock.On() no teste
  2. Ajustar assertion: s.Equal([]Aluno{}, result) → s.Empty(result)
  3. Adicionar sync.Mutex no map de resultados

Aplicar fixes? (todos / selecionar / nenhum)
```

**PARAR e aguardar aprovação antes de aplicar qualquer fix.**

## Passo 6 — Coverage report (se solicitado)

```bash
cd /home/claude/projects/estrategia/monolito
APP_ENV=testing go test -tags testing -p 16 -count=1 -coverprofile=coverage.out ./apps/<app>/internal/services/...
go tool cover -func=coverage.out | grep -v '100.0%' | sort -t: -k3 -n
```

Apresentar:

```
Coverage Report — apps/<app>/internal/services/

  Pacote                          Coverage
  aluno/service.go                 78.5%
  aluno/create.go                  92.3%
  aluno/search.go                  45.0%  ← baixa
  curso/service.go                 88.1%

  Funções sem cobertura:
  - aluno/search.go:SearchByFilters (0%)
  - aluno/search.go:buildSearchQuery (0%)

Deseja que eu crie testes para as funções descobertas?
```

## Passo 7 — Mock validation

Verificar se mocks estão sincronizados com interfaces:

```bash
cd /home/claude/projects/estrategia/monolito
make mocks-<app>
git diff --stat apps/<app>/mocks/
```

Se houver diferenças:

```
Mocks desatualizados:
  apps/ldi/mocks/AlunoServiceMock.go  +15 -3

Interfaces modificadas:
  - AlunoService.Create: novo parâmetro `opts CreateOptions`
  - AlunoService.Delete: removido

Atualizar mocks e ajustar testes afetados? (sim/não)
```

## Passo 8 — Fix proposals

Para cada falha aprovada pelo dev:

1. **Aplicar o fix** usando Edit
2. **Re-rodar apenas o teste afetado** para confirmar
3. **Verificar que não quebrou outros testes** no mesmo pacote
4. **Reportar resultado**

```
Fixes aplicados:

  # Teste                    Status    Ação
  1 TestCreateAluno          ✅ Pass   Regenerou mocks + atualizou mock.On()
  2 TestSearchAluno_NotFound ✅ Pass   Ajustou assertion
  3 TestBulkUpdate           ✅ Pass   Adicionou sync.Mutex

  Todos os testes do pacote passando: ✅
```

## Regras de Ouro

| Regra | Detalhe |
|---|---|
| Sempre `APP_ENV=testing` | Sem isso, configs de produção são carregadas |
| Sempre `-tags testing` | Build tags controlam inclusão de fixtures e test helpers |
| Sempre `-count=1` | Desabilita cache de testes — garante execução fresh |
| Mock gerado, não manual | `make mocks-<app>` usa mockery — nunca editar mocks manualmente |
| Teste no mesmo pacote | `_test.go` no mesmo diretório, package pode ser externo (`_test`) |
| Nunca pular Pre-flight | Build deve passar antes de rodar testes |
| Fix aprovado antes de aplicar | Sempre apresentar proposta e aguardar confirmação |
| Re-rodar após fix | Confirmar que o fix resolve e não quebra vizinhos |

## Erros Comuns

- **Rodar sem `-tags testing`**: imports condicionais não resolvem, `undefined` errors
- **Rodar sem `APP_ENV=testing`**: teste tenta conectar em DB de produção
- **Mock desatualizado**: interface mudou mas `make mocks-<app>` não foi rodado
- **`-count=1` esquecido**: teste usa cache e mostra resultado antigo
- **Testar pacote errado**: handler teste falha porque service mudou — testar service primeiro
- **Race condition mascarada**: teste passa sem `-race` mas falha com `-race`
- **Fixture desatualizada**: struct mudou mas fixtures em `testdata/` não foram atualizadas
