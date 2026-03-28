# /code:manager — Project Manager / Orchestrator

Orquestrador central que coordena agentes, mantém board de controle, despachando skills necessárias.

## Responsabilidades

- [ ] Criar arquivo manager em `/workspace/obsidian/manager/FUK2-XXXXX.md`
- [ ] Estrutura: jira + timeline macro + dashboard status + agentes + bloqueadores
- [ ] Despachar agentes usando `/code:refine`, `/code:guru`, `/code:plan`, `/code:develop`, `/code:qa`
- [ ] Manter board de controle ATUALIZADO (status real de cada fase)
- [ ] Coordenar handoff entre agentes (passar contexto)
- [ ] Sumarizar boards antigos (consolidar lições, extrair learnings)
- [ ] Rastrear bloqueadores globais (não é só bug, é dependência entre subtasks)

## Input

```
/code:manager create FUK2-987213
```

Ou com contexto:

```
/code:manager
Ação: create
Jira: FUK2-987213
Título: Refactor Auth Flow para JWT
Categoria: estrategia
Agente Principal: Coruja
```

Ou summarize:

```
/code:manager summarize FUK2-999888
```

## Output

### Criar Manager Board

Cria `/workspace/obsidian/manager/FUK2-987213-refactor-auth.md` com:

```markdown
---
manager: true
---

# FUK2-987213: Refactor Auth Flow para JWT

**Status Geral**: 🟡 Em Desenvolvimento (60%)

## Metadata

| Campo | Valor |
|-------|-------|
| **Jira** | [FUK2-987213](https://estrategia.atlassian.net/browse/FUK2-987213) |
| **Criado** | 2026-03-27 10:00 UTC |
| **Deadline** | 2026-04-03 |
| **Agente Principal** | Coruja |
| **Status Geral** | Em Desenvolvimento |
| **% Completo** | 60% |

---

## 📊 Dashboard de Controle

| Fase | Status | Agente | Progresso | Bloqueadores | Link |
|------|--------|--------|-----------|---------------|------|
| **REFINING** | ✅ COMPLETO | Coruja | 100% | Nenhum | [board](../workshop/estrategia/FUK2-987213-refactor-auth.md#refining) |
| **ATTENTION** | ✅ COMPLETO | Guru | 100% | Nenhum | [board](../workshop/estrategia/FUK2-987213-refactor-auth.md#attention) |
| **PLANNING** | ✅ COMPLETO | Coruja | 100% | Nenhum | [board](../workshop/estrategia/FUK2-987213-refactor-auth.md#planning) |
| **DEVELOPING** | 🟡 EM PROGRESSO | Coruja | 65% | Logout strategy | [board-A](../workshop/estrategia/FUK2-987213-refactor-auth.md#developing) |
| **QA** | ⏳ AGUARDANDO | User | 0% | DEVELOPING finalizar | [board](../workshop/estrategia/FUK2-987213-refactor-auth.md#qa) |
| **WAITING** | ⏳ AGUARDANDO | User | 0% | QA passar | — |
| **DONE** | ⏳ AGUARDANDO | — | 0% | Staging OK | — |

---

## 🗺️ Estrutura de Boards

```
Tarefas: 1 Jira = 1 pasta = 1 board devflow

/workspace/obsidian/workshop/estrategia/
├── FUK2-987213-refactor-auth.md  ← BOARD DEVFLOW (detalhe)
└── (outras tasks...)

/workspace/obsidian/manager/
├── FUK2-987213-refactor-auth.md  ← MANAGER BOARD (orquestrador)
└── (outras managers...)
```

---

## 📋 Agentes Atribuídos

| Fase | Agente | Status | Última Ação | Próxima Ação |
|------|--------|--------|-------------|--------------|
| REFINING | Coruja | ✅ Completo | 2026-03-27 11:00 | Moveu pra ATTENTION |
| ATTENTION | Guru | ✅ Completo | 2026-03-27 16:30 | Guru brainstorm ok, moveu pra PLANNING |
| PLANNING | Coruja | ✅ Completo | 2026-03-28 10:00 | Quebrou em A/B/C/D, moveu pra DEVELOPING |
| DEVELOPING-A | Coruja | 🟡 65% | 2026-03-30 14:00 | Continua logout impl, roda testes |
| DEVELOPING-B | Coruja | ✅ 100% | 2026-03-29 17:00 | Vue pronto, aguarda A/D |
| DEVELOPING-C | Coruja | 🟡 70% | 2026-03-31 10:00 | Nuxt middleware fix, 2h mais |
| DEVELOPING-D | Coruja | 🔴 40% | 2026-03-31 14:00 | Docs faltando migration guide |
| QA | You | ⏳ Não iniciou | — | Testa quando DEVELOPING = 100% |

---

## 🚨 Bloqueadores Globais

| Bloqueador | Fase | Severidade | Dono | ETA Fix | Status |
|------------|------|-----------|------|---------|--------|
| Logout strategy indefinida | DEVELOPING-A | 🔴 CRÍTICO | Coruja | 2026-03-31 15:00 | ✅ RESOLVIDO (revoked_at field) |
| Migration guide faltando | DEVELOPING-D | 🟡 MÉDIO | Coruja | 2026-04-02 09:00 | ⏳ Em progresso |
| Nuxt middleware compat | DEVELOPING-C | 🔴 CRÍTICO | Coruja | 2026-04-01 10:00 | ✅ RESOLVIDO |
| Mobile v1 response format | DEVELOPING-A | 🔴 CRÍTICO | Coruja | 2026-03-31 15:30 | ✅ RESOLVIDO |

---

## 📈 Timeline Macro

```
┌─────────────────────────────────────────────────────────────┐
│ 2026-03-27        2026-03-28         2026-04-01   2026-04-03│
│  ↓                 ↓                   ↓             ↓       │
│ REFINING ─→ ATTENTION ─→ PLANNING ──→ DEVELOPING ──→ QA ──→ DONE
│  1d        0.5d       0.5d             3d           2d       0.5d
│ ✅         ✅         ✅         🟡 (65%, bloq)  ⏳         ⏳
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 Links para Boards Detalhados

- **REFINING/ATTENTION/PLANNING/DEVELOPING/QA**: [`FUK2-987213-refactor-auth.md`](../workshop/estrategia/FUK2-987213-refactor-auth.md)
  - Este é o board DEVFLOW com tudo detalhado (checkboxes, bugs, timeline, etc)
  - Manager sincroniza com este board

---

## 🎯 Próximos Passos

1. **Coruja**: Finalizar DEVELOPING-A (logout), roda testes unit
2. **Coruja**: Continua DEVELOPING-C (Nuxt), previsto 2h
3. **Coruja**: Termina DEVELOPING-D (docs migration guide)
4. **You**: Quando DEVELOPING = 100%, roda QA (10 testes)
5. **You**: Aprova ou pede ajustes em WAITING
6. **DevOps**: Deploy staging/produção

---

## 📊 Métricas

| Métrica | Target | Atual | Status |
|---------|--------|-------|--------|
| **% DEVELOPING** | 100% | 65% | 🟡 2h mais |
| **Bugs encontrados** | <5 | 3 | ✅ OK |
| **Bugs resolvidos** | 100% | 100% | ✅ OK |
| **Timeline variance** | ±1d | +0.5d | ✅ OK (no prazo) |
| **Bloqueadores ativos** | 0 | 0 | ✅ Todos resolvidos |

---

## 🧠 Lições em Tempo Real

- ✅ Guru brainstorm eliminou design uncertainty
- ⚠️ Mobile v1 compat deveria ser testada CEDO (não na QA final)
- ⚠️ Framework migration (Nuxt 2→3) requer prep melhor
- ✅ Vue implementação foi sem bugs (bom padrão)

---

## Status Este Momento

- **Último atualizado**: 2026-04-01 17:00 UTC
- **Por**: Coruja + Manager
- **Próxima sync**: 2026-04-02 09:00 UTC (QA check-in)

```

---

### Summarize Antigo Board

Se manager resumir um board antigo, consolida:

```markdown
# Resumo — FUK2-999888 (Finalizado 2026-03-25)

**Resultado**: ✅ COMPLETO, Produção 2026-03-25 14:00

**Tempo total**: 8 dias (estimado 7d, variance +1d por nuance de design)

**Agentes envolvidos**:
- Coruja: REFINING, PLANNING, DEVELOPING (backend/frontend)
- Guru: ATTENTION (brainstorm 2 questões)
- User: QA (10 testes, 1 issue encontrada/resolvida)

**Bugs & Fixes**:
- 3 bugs encontrados: camelCase response (fix: 2h), nuxt compat (fix: 3h), refresh concurrency (adiar)
- Taxa de primeira tentativa: 85% (boa!)

**Lições Aprendidas**:
1. Mobile client compat testa CEDO, não fim
2. Nuxt 3 migration precisa doc melhor
3. Framework changes afetam tempo (add 20%)

**Próximo projeto**: Aplicar lições, estimado 6d (vs 8d este)

**Conhecimento conservado**: Links pra todos boards, timeline completo, métricas
```

---

## Checklist Pós-Manager Create

- [ ] Arquivo criado em `/workspace/obsidian/manager/FUK2-XXXXX.md`
- [ ] Metadata completo (Jira, datas, agente)
- [ ] Dashboard de controle pronto
- [ ] Links para board devflow
- [ ] Agentes atribuídos
- [ ] Bloqueadores rastreados
- [ ] Timeline macro visível
- [ ] Próximos passos claros
- [ ] Ready pra dispatcher chamar `/code:refine`, `/code:guru`, etc

## 🌐 Related Skills & Agents

### Skills que Manager Orquestra

| Skill | Quando Chamar | Contexto |
|-------|---------------|---------|
| `/code:refine` | Início | Mapear requisito |
| `/code:guru` | Se complexo | Brainstorm design |
| `/code:plan` | Após ATTENTION | Quebrar em subtasks |
| `/code:develop` | Paralelo | Implementar A/B/C/D |
| `/code:qa` | Quando DEVELOPING 100% | Testes funcionais |
| `/coruja` | Estratégia | Especialista implementação |
| `/meta:obsidian` | Real-time | Sincronizar status |

### Agentes Especialistas

| Agente | Quando Invocar | Por Quê |
|--------|---------------|--------|
| **Coruja** | Estratégia principal | Especialista full-stack |
| **Wanderer** | Debug, análise | Root cause investigation |
| **Wiseman** | Consolidação | Impacto sistêmico, lições |

### Exemplo: Manager Orquestrando

```
/code:manager create FUK2-987213

1. Manager cria board em /manager/FUK2-987213.md
2. Manager chama /code:refine
   → Coruja refina
   → Manager sincroniza dashboard (REFINING ✅)

3. Se complexo:
   → Manager chama /code:guru
   → Guru brainstorm
   → Manager sincroniza (ATTENTION ✅)

4. Manager chama /code:plan
   → Coruja quebra
   → Manager sincroniza (PLANNING ✅)

5. Manager chama /code:develop (paralelo)
   → Coruja-A implementa
   → Coruja-B implementa
   → Coruja-C implementa
   → Manager monitora % real-time, rastreia bugs

6. Quando DEVELOPING 100%:
   → Manager chama /code:qa
   → You testa
   → Manager consolida

7. Quando DONE:
   → Manager summarize
   → Wiseman consolida lições
```

## Checklist Pós-Manager Summarize

- [ ] Board antigo analisado
- [ ] Lições extraídas (via Wiseman)
- [ ] Tempo total calculado
- [ ] Bugs/fixes documentados
- [ ] **Contexto máximo**: Consultou agentes pra consolidar
- [ ] Conhecimento consolidado pra próximo projeto
- [ ] Arquivo atualizado com resumo
