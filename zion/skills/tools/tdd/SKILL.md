# Skill: tdd — Test-Driven Development

> RED-GREEN-REFACTOR. Teste antes de codigo. Sem excecoes.

---

## Quando usar

- Implementar feature nova (handler, service, componente)
- Corrigir bug (teste que reproduz o bug PRIMEIRO, depois fix)
- Quando o dev pedir explicitamente "modo TDD" ou "test first"
- Quando feature.md tiver `## Mode: TDD`

## Ciclo

### 1. RED — Escrever teste que falha

- Descrever o comportamento esperado como teste
- Rodar o teste — **DEVE falhar**
- Se passa: o teste esta errado ou a feature ja existe — investigar
- Confirmar que falha pelo **motivo certo** (assertion fail, nao erro de compilacao)

### 2. GREEN — Codigo minimo pra passar

- Implementar **APENAS** o necessario pra o teste passar
- Sem extras, sem otimizacao prematura, sem features bonus
- Rodar o teste — **DEVE passar**
- Rodar testes vizinhos — **NAO devem quebrar**

### 3. REFACTOR — Limpar mantendo verde

- Melhorar nomes, extrair duplicacao, simplificar
- Rodar testes **depois de cada refactor**
- Se quebrou: desfazer e tentar de novo

### 4. COMMIT — Atomo semantico

- Cada ciclo RED-GREEN-REFACTOR = 1 commit (ou par de commits)
- Formato sugerido: `test: add TestXxx` seguido de `feat: implement Xxx`
- Commits pequenos sao mais faceis de revisar e reverter

### 5. REPETIR — Proximo comportamento

Voltar ao passo 1 para o proximo requisito/comportamento.

## Dominio: Go monolito

- **Testes:** `_test.go` no mesmo pacote, testify suites (`suite.Suite`)
- **Flags:** `APP_ENV=testing`, `-tags testing`, `-count=1`
- **Mocks:** `make mocks-<app>` (mockery) — nunca editar mock manualmente
- **Execucao:** ref skill `monolito/go-test` para rodar, analisar falhas e coverage
- **Exemplo de ciclo:**
  1. RED: criar `TestCreateAluno` com mock de repo, assertar retorno esperado
  2. Rodar: `APP_ENV=testing go test -tags testing -v -run TestCreateAluno ./apps/ldi/internal/services/aluno/...` → FAIL
  3. GREEN: implementar `CreateAluno` no service — minimo pra passar
  4. Rodar: mesmo comando → PASS
  5. REFACTOR: extrair validacao, renomear, simplificar
  6. COMMIT: `test: add TestCreateAluno` + `feat: implement CreateAluno`

## Dominio: Vue frontends (bo-container / front-student)

- **Testes:** jest, `@vue/test-utils`, `mount`/`shallowMount`
- **Stubs:** dependencias externas (store, router, API calls)
- **Execucao:** `yarn test` ou `yarn test:unit`
- **Exemplo de ciclo:**
  1. RED: criar teste de componente que espera render de lista de items
  2. Rodar: `yarn test --testPathPattern=MeuComponente` → FAIL
  3. GREEN: implementar componente minimo com v-for
  4. Rodar → PASS
  5. REFACTOR: extrair item pra subcomponente se necessario

## Anti-patterns

| Anti-pattern | Por que e ruim | O que fazer |
|-------------|---------------|-------------|
| Escrever codigo antes do teste | Perde o ciclo RED — nao sabe se teste detectaria bug | **DELETAR** o codigo e recomecar do RED |
| Teste que testa implementacao (nao comportamento) | Quebra quando refatora, nao pega bugs reais | Testar inputs → outputs, nao detalhes internos |
| Teste que nunca pode falhar (tautologia) | Falsa seguranca — nao valida nada | Verificar que o teste FALHA quando comportamento muda |
| Mock que replica a implementacao inteira | Testa o mock, nao o codigo | Mock so interfaces externas, testar logica real |
| Pular REFACTOR "pra ir mais rapido" | Divida tecnica acumula, proximos ciclos ficam mais lentos | REFACTOR e parte do ciclo, nao bonus |

## Integracao com orquestrador

- Se `feature.md` tiver `## Mode: TDD`, subagentes seguem esta skill
- Cada task do plano de implementacao vira um ciclo RED-GREEN-REFACTOR
- Code review valida que testes existem ANTES do codigo de producao
- Commits seguem a sequencia: teste → implementacao → refactor

## Relacao com outras skills

| Skill | Relacao |
|-------|---------|
| `monolito/go-test` | Complementar — go-test roda/analisa testes existentes; tdd governa a sequencia de criacao |
| `tools/debug` | Bug fix com TDD: Fase 1 do debug (reproduzir) = RED do TDD (teste que falha reproduzindo o bug) |
| `orquestrador/orquestrar-feature` | Orquestrador despacha subagentes; se mode=TDD, subagentes usam esta skill |
