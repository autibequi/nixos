# /code:qa — Quality Assurance (Manual Testing)

Testes funcionais, fluxos reais, edge cases. Seu controle de qualidade.

## Responsabilidades

- [ ] Ler DEVELOPING (implementação completa)
- [ ] Testar fluxos de usuário (não unit tests)
- [ ] Testar edge cases (timeout, erro rede, concorrência)
- [ ] Se achar bug:
  - Se trivial → anota + volta pra DEVELOPING pra fix
  - Se complexo → pode "adiar pra sprint próximo" (low priority)
- [ ] Preencher seção QA com testes
- [ ] Marcar checkboxes conforme testa
- [ ] Quando tudo testado → WAITING (aguarda seu OK)

## Input

```
/code:qa FUK2-XXXXX
```

Ou com contexto:

```
/code:qa
Arquivo: /workspace/obsidian/workshop/estrategia/FUK2-987213-refactor-jwt.md
Foco: Fluxos de login, refresh, logout, compatibilidade mobile v1
```

## Output

Preenche **QA** com:
- ✅ Testes que passaram
- ❌ Problemas encontrados (com fix status)
- ⚠️ Problemas conhecidos (adiar pra sprint próximo)
- 📊 Resumo: "9/10 testes passando, 1 bloqueador resolvido"

## Exemplo

```
## QA

**Status**: 🟡 Em Progresso (2026-03-31 10:00 - 2026-04-01 17:00)

### ✅ Testes que Passaram

- [x] Fluxo básico: login → access + refresh tokens ✅
- [x] Bearer token: /api/protegido funciona com "Authorization: Bearer" ✅
- [x] Refresh automático: access expira, app chama /refresh, novo access funciona ✅
- [x] Logout: limpa tokens, /api/protegido retorna 401 ✅
- [x] Multiple devices: logout em um não afeta outro ✅
- [x] Session fallback: cliente antigo com cookie funciona ✅

### ❌ Problemas Encontrados

**Problema 1**: Mobile v1 incompatível (2026-03-31 14:00)
- Esperava: `{access_token, refresh_token}` (snake_case)
- Recebeu: `{accessToken, refreshToken}` (camelCase)
- Status: **BLOQUEADOR**
- ✅ FIX: Revert pra snake_case
- ✅ Retest: Mobile OK ✅

**Problema 2**: Nuxt middleware (2026-03-31 16:00)
- /dashboard deveria redirecionar anônimos
- Middleware Nuxt 2 syntax não funciona em Nuxt 3
- Status: **BLOQUEADOR**
- ✅ FIX: defineRouteMiddleware() syntax
- ✅ Retest: /dashboard protegido ✅

**Problema 3**: Refresh concurrency (2026-04-01 11:00)
- 2 requests simultâneos com token expirado
- Ambos chamam /refresh (deveria ser 1, depois reutilizar)
- Status: **LOW PRIORITY**, adiar Sprint 46
- ⏳ Workaround: Implementar refresh mutex (próximo sprint)

### 📊 Resumo

| Teste | Status | Bloqueador | Resolvido |
|-------|--------|-----------|-----------|
| Fluxo básico | ✅ | — | ✅ |
| Bearer token | ✅ | — | ✅ |
| Refresh automático | ✅ | — | ✅ |
| Logout | ✅ | — | ✅ |
| Multiple devices | ✅ | — | ✅ |
| Mobile v1 compat | ❌ | ✅ | ✅ FIXED |
| Nuxt middleware | ❌ | ✅ | ✅ FIXED |
| Refresh concurrency | ⚠️ | — | ⏳ ADIAR |

**Status Final**: 6/8 testes passando. 2 bloqueadores resolvidos. Ready pra WAITING.
```

## 🌐 Related Skills & Agents

### Skills para Testes

| Skill | Como Usar |
|-------|-----------|
| `/coruja:qa` | Se Estratégia, especialista testa |
| `/code:review` | Validar que implementação é testável |
| `/meta:feed` | Ver logs recentes de erros similares |

### Agentes para Testes Funcionais

| Agente | Quando Usar | Por Quê |
|--------|-----------|--------|
| **Wanderer** | Debug de falha obscura | Explora codebase pra root cause |
| **Wiseman** | Impacto sistêmico de bug | Consolida se bug é crítico ou menor |
| **Coruja** | Testes integração Estratégia | Especialista frontend/backend |

### Exemplo: QA com Contexto

```
Teste: "Login flow — backend + Vue + Nuxt"

1. Testa manual
2. Encontra bug: mobile incomp
3. /coruja:backend → Coruja investiga response format
4. /wanderer → Wanderer busca padrão em outros services
5. /wiseman → Wiseman consolida se é critical ou low-priority

RESULTADO: Bug categorizado (CRITICAL/MÉDIO/LOW), fix assinalado
```

## Checklist Pós-QA

- [ ] QA preenchido com todos testes rodados
- [ ] Testes passando marcados ✅
- [ ] Problemas encontrados anotados (problema + fix + status)
- [ ] **Contexto máximo**: Consultou agentes pra categorizar bugs
- [ ] Bloqueadores resolvidos ou adiados (com reasoning)
- [ ] Timeline atualizada (datas de bugs/fixes)
- [ ] Ready pra WAITING (aguarda seu sign-off)
