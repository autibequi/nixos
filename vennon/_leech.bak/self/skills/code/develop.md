# /code:develop — Execute Development

Implementa subtask, marca checkboxes conforme progride, rastreia bugs.

## Responsabilidades

- [ ] Ler PLANNING (subtasks + checkboxes)
- [ ] Pega uma subtask (A, B, C, ou D)
- [ ] Implementa checkbox por checkbox
- [ ] Se achar bug → anota no checkbox + fix + retesta
- [ ] Marca `[x]` quando pronto (testado)
- [ ] Atualiza timeline com progresso
- [ ] Quando tudo `[x]` → pronto pra QA

## Input

```
/code:develop FUK2-987213-A
```

Ou com contexto:

```
/code:develop
Arquivo: /workspace/obsidian/workshop/estrategia/FUK2-987213-refactor-jwt.md
Subtask: A) Backend (Go)
Checkboxes: JWT service, Middleware, DB migration, Endpoints, Config, Tests
```

## Output

Preenche **DEVELOPING** com:
- ✅ Checkboxes `[x]` quando implementado
- ⚠️ Bugs anotados inline (problema + fix + status)
- 🔄 Iterações visíveis (foi pra subtask B, volta A pra fix)
- 📊 Status: "60% code, 80% tests" etc

## Exemplo

```
## DEVELOPING

### A) Backend (Go) — Status: 🟡 Em Progresso (65%)

**Concluído:**
- [x] JWT service: GenerateToken, VerifyToken
  - ⚠️ BUG ENCONTRADO: VerifyToken não valida TTL
  - ✅ FIX: Adicionou check `if (claims.exp < now) return false`
  - ✅ Testado

- [x] Middleware: AuthMiddleware
  - ✅ Tudo funciona

- [x] DB: refresh_tokens table
  - ✅ Migration pronta

**Em Progresso:**
- [x] Endpoints: /auth/login, /auth/refresh
  - ✅ Login OK
  - ❌ Refresh bloqueado: como invalidar token?
  - ✅ SOLUÇÃO: Usar revoked_at field
  - Status: Aguardando implementação

- [ ] /auth/logout
  - ⏳ Bloqueado por refresh revoke strategy

**Tests:**
- [x] GenerateToken — 3 casos ✅
- [x] VerifyToken — 5 casos ✅
- [ ] Logout — 3 casos (⏳ bloqueado)
```

## 🌐 Related Skills & Agents

### Skills para Implementação

| Skill | Como Usar |
|-------|-----------|
| `/coruja:*` (backend/frontend) | Se Estratégia, usar especialistas |
| `/code:review` | Validar implementação conforme avança |
| `/code/tdd` | Unit tests, TDD padrão |
| `/leech` | Se infra/DevOps envolvido |

### Agentes para Desenvolvimento

| Agente | Quando Usar | Por Quê |
|--------|-----------|--------|
| **Coruja** | Estratégia (principal) | Implementa o código mesmo |
| **Wanderer** | Debug, análise padrões | Encontra bugs via análise |
| **Wiseman** | Impacto sistêmico | Valida design decisions mid-implement |

### Exemplo: Develop com Contexto

```
Subtask A) Backend (Go)

1. /coruja:backend → Coruja implementa GenerateToken
2. /code/tdd → Unit tests conforme escreve
3. Se achar bug:
   - Anota no checkbox
   - /coruja:debug → Wanderer analisa
   - Fix + retest
4. /code:review → validar antes de mover pra B

RESULTADO: Checkbox [x] com "testado", bugs rastreados
```

## Checklist Pós-Develop

- [ ] Subtask tem checkboxes de implementação
- [ ] Checkboxes marcados `[x]` têm status "testado" ou "com bug anotado"
- [ ] Bugs encontrados têm fix descrito
- [ ] **Contexto máximo**: Consultou agentes durante impl
- [ ] Timeline atualizada com datas de bugs/fixes
- [ ] Quando 100% [x] → ready pra QA
