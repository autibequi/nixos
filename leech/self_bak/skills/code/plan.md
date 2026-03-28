# /code:plan — Plan Task Breakdown

Quebra tarefa em subtasks granulares, define ordem, dependências.

## Responsabilidades

- [ ] Ler REFINING + ATTENTION (requisito + decisões)
- [ ] Quebrar em subtasks (A, B, C, D, ... por repositório/módulo)
- [ ] Definir checkboxes mini dentro de cada subtask
- [ ] Preencher seção PLANNING
- [ ] Definir ordem/dependências
- [ ] Pronto pra DEVELOPING

## Input

```
/code:plan FUK2-XXXXX
```

Ou com contexto:

```
/code:plan
Arquivo: /workspace/obsidian/workshop/estrategia/FUK2-987213-refactor-jwt.md
Requisito: JWT auth refactor
Decisões já tomadas: access 15m, refresh 7d, session fallback
```

## Output

Preenche **PLANNING** com:
- 🎯 **Decisões Finais** (recap do que foi decidido em ATTENTION)
- 📋 **Quebra em Subtasks** (A, B, C, D...)
  - A) [Descrição] — dependências
  - B) [Descrição] — paralelo com A
  - C) [Descrição] — pode começar depois B
  - D) [Descrição] — docs/final

## Exemplo

```
## PLANNING

**Decisões Finais (Guru + Coruja):**
- ✅ Access 15m + Refresh 7d
- ✅ Claims: user_id, email, roles, scopes, iat, exp
- ✅ Session + JWT coexistem
- ✅ Revoke: TTL 15m (logout via refresh skip)

**Quebra em Subtasks:**

### A) Backend (Go) — FUK2-987213-A
- JWT service: GenerateToken, VerifyToken, RefreshToken
- Middleware: AuthMiddleware
- DB: refresh_tokens table
- Endpoints: /auth/login, /auth/refresh, /auth/logout
- Config: secrets, TTL
- Backwards compat: session + JWT
- Tests: 15+ cenários

### B) Frontend Vue — FUK2-987213-B
- Store: tokens state
- Auth module: storeTokens, getAccessToken
- Axios interceptor: Bearer, 401 retry
- Logout: limpa tokens
- Middleware: protege rotas
- Tests: 15+ cenários

### C) Frontend Nuxt — FUK2-987213-C
- Auth plugin: Pinia + axios
- useAuth composable
- Interceptor
- Middleware
- Pages adapt
- Tests: 15+ cenários

### D) Docs & DevOps — FUK2-987213-D
- API docs
- Migration guide
- Diagrama
- Security
- Troubleshooting
- Monitoring setup
```

## 🌐 Related Skills & Agents

### Skills para Estruturar Plan

| Skill | Como Usar |
|-------|-----------|
| `/coruja:architecture` | Se Estratégia, mapeia arquitetura repos |
| `/code:review` | Validar design decisions antes de PLANNING final |
| `/meta:obsidian:graph` | Visualizar dependências entre subtasks |

### Agentes para Quebra

| Agente | Quando Usar | Por Quê |
|--------|-----------|--------|
| **Coruja** | Estratégia | Sabe quebrar em backend/frontend/docs |
| **Wiseman** | Impacto cross-repo | Consolida impacto sistêmico da quebra |
| **Wanderer** | Padrões similares | Busca projetos similares pra padrões |

### Exemplo: Plan com Contexto

```
Decisões já tomadas (via Guru)

1. /coruja:architecture → mapeia repos afetados
2. /meta:obsidian:graph → mostra dependências conhecidas
3. Wanderer → "Projetos similares, como foram quebrados?"
4. Wiseman → "Essa quebra é sustentável? Impacto?"

RESULTADO: Subtasks A/B/C/D com ordem e dependências otimizadas
```

## Checklist Pós-Plan

- [ ] PLANNING preenchido com decisões + subtasks
- [ ] Cada subtask tem checkboxes mini (15-30 itens)
- [ ] Ordem/dependências claras (A → B → C ou paralelo)
- [ ] **Contexto levantado**: Consultou skills/agentes pra validar quebra
- [ ] Ready pra DEVELOPING (agente pode começar imediatamente)
- [ ] Timeline atualizada (data/hora planning completo)
